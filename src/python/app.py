import json
import sys
import os

from pagerduty import RestApiV2Client, Error
from config import *

def lambda_handler(event, context):
    print('Event Received: {}'.format(json.dumps(event)))

    # Parse event directly as JSON
    if 'detail' not in event:
        return generate_return_body(400, 'Invalid event structure - missing detail')
    
    detail = event['detail']
    
    # Only process OAuthClient events
    if 'OAuthClient' not in detail.get('topicName', ''):
        return generate_return_body(200, 'Not an OAuth Client event')
    
    oauthClientEvent = detail.get('eventBody', {})

    # only respond to deleted clients
    if oauthClientEvent.get('action') != 'Delete':
        return generate_return_body(200, 'OAuth Client not deleted')

    deleteTime = ''
    for propertyChange in oauthClientEvent.get('propertyChanges', []):
        if propertyChange.get('property') == 'deleted_on':
            deleteTime = propertyChange.get('newValues', [''])[0]
            break

    entity = oauthClientEvent.get('entity', {})
    print('{} has been deleted at {}'.format(entity.get('name', 'Unknown'), deleteTime))

    try:
        # create a pager duty incident with the client id and deletion time
        incident = notify_pager_duty(entity.get('id', 'Unknown'), deleteTime, pager_duty_service_id)
        print('PagerDuty incident with ID {} has been created'.format(entity.get('id', 'Unknown')))
    except Error as e:
        if e.response:
            return generate_return_body(e.response.status_code, e.response.msg)
        else:
            return generate_return_body(500, str(e))

    return generate_return_body(200, 'PagerDuty incident created')

def notify_pager_duty(oauth_client_id, deleted_on, service_id):
    session = RestApiV2Client(pager_duty_api_key)

    details = 'OAuth Client with ID {} has been deleted at {}'.format(oauth_client_id, deleted_on)

    payload = {
        'type': 'incident',
        'title': 'OAuth Client Deleted',
        'service': {
            'id': service_id,
            'type': 'service_reference'
        },
        'body': {
            'type': 'incident_body',
            'details': details
        },
    }

    return session.rpost('/incidents', json=payload)

def generate_return_body(status_code, message):
    return {
        'statusCode': status_code,
        'body': json.dumps({
            'message': message
        })
    }

# For running locally. Pass in the path to a valid event in a JSON file to test
if __name__ == '__main__':
    file_path = sys.argv[1]
    if file_path != None and os.path.exists(file_path):
        with open(file_path, 'r') as f:
            print(lambda_handler(json.load(f), 'context'))