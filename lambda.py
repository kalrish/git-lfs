import base64
import json
import logging
import os

import boto3

logger = logging.getLogger(
)

s3_methods = {
    'download': 'get_object',
    'upload': 'put_object',
}

http_methods = {
    'download': 'GET',
    'upload': 'PUT',
}


def handler(event, context):
    # FIXME: make configurable
    logger.setLevel(
        logging.DEBUG,
    )

    logger.debug(
        'event: %s',
        event,
    )

    headers = event['headers']
    is_base64_encoded = event['isBase64Encoded']

    try:
        authorization = headers['authorization']
    except KeyError:
        logger.error(
            'missing Authorization header',
        )

        response = {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/vnd.git-lfs+json',
                'LFS-Authenticate': 'Basic realm="Git LFS", charset="UTF-8"',
            },
            'body': '{"message":"missing authentication","documentation_url":"https://mo.in/"}',
            'isBase64Encoded': False,
        }
    else:
        logger.debug(
            'Authorization header present',
        )

        pieces = authorization.split(
            maxsplit=1,
            sep=' ',
        )

        authorization_type = pieces[0]
        authorization_credentials = pieces[1]

        logger.debug(
            'authorization type: %s',
            authorization_type,
        )

        if authorization_type == 'Basic':
            logger.debug(
                'encoded authorization credentials: %s',
                authorization_credentials,
            )

            authorization_credentials = base64.b64decode(
                authorization_credentials,
                validate=True,
            )

            authorization_credentials = authorization_credentials.decode(
                'utf-8',
            )

            logger.debug(
                'decoded authorization credentials: %s',
                authorization_credentials,
            )

            pieces = authorization_credentials.split(
                sep=':',
            )

            username = pieces[0]
            password = pieces[1]

            logger.debug(
                'username: %s',
                username,
            )

            logger.debug(
                'password: %s',
                password,
            )

            credentials_valid = validate_credentials(
                password=password,
                username=username,
            )

            if credentials_valid:
                logger.debug(
                    'credentials are valid',
                )

                body = event['body']

                if is_base64_encoded:
                    body = base64.b64decode(
                        body,
                        validate=True,
                    )

                data = json.loads(
                    body,
                )

                logger.debug(
                    'body: %s',
                    data,
                )

                response = handler_batch(
                    data=data,
                )
            else:
                logger.debug(
                    'credentials are not valid',
                )

                response = {
                    'statusCode': 401,
                    'headers': {
                        'Content-Type': 'application/vnd.git-lfs+json',
                        'LFS-Authenticate': 'Basic realm="Git LFS", charset="UTF-8"',
                    },
                    'body': '{"message":"invalid credentials","documentation_url":"https://mo.in/"}',
                    'isBase64Encoded': False,
                }
        else:
            response = {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/vnd.git-lfs+json',
                    'LFS-Authenticate': 'Basic realm="Git LFS", charset="UTF-8"',
                },
                'body': '{"message":"wrong authentication method","documentation_url":"https://mo.in/"}',
                'isBase64Encoded': False,
            }

    return response


def validate_credentials(password, username):
    credentials_valid = username == 'foo' and password == 'bar'

    return credentials_valid


def handler_batch(data):
    operation = data['operation']

    # FIXME: put this in the proper location
    bucket = os.environ['Bucket']
    partition = os.environ['AWS_PARTITION']
    region = os.environ['AWS_REGION']

    s3_method = s3_methods[operation]
    http_method = http_methods[operation]

    s3 = boto3.client(
        's3',
    )

    request_objects = data['objects']

    response_objects = list(
    )

    for request_object in request_objects:
        oid = request_object['oid']

        # TODO: find out whether a different key scheme could improve performance
        object_key = oid

        s3_method_params = dict(
        )

        s3_method_params['Bucket'] = bucket
        s3_method_params['Key'] = object_key

        if operation == 'upload':
            s3_method_params['StorageClass'] = storage_class

        href = s3.generate_presigned_url(
            ClientMethod=s3_method,
            HttpMethod=http_method,
            Params=s3_method_params,
            ExpiresIn=50,
        )

        response_object = {
            'oid': oid,
            'size': request_object['size'],
            'authenticated': True,
            'actions': {
                operation: {
                    'href': href,
                    'expires_in': 50,
                },
            },
        }

        response_objects.append(
            response_object,
        )

    response = {
        'transfer': 'basic',
        'objects': response_objects,
    }

    return response
