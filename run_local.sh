set -e

CURRENT_DIR=$(pwd)

export PAGER_DUTY_API_KEY="your-api-key"
export PAGER_DUTY_SERVICE_ID="pagerduty-service-id"

case "$1" in

    "python")
        cd src/python
        python3 app.py ${CURRENT_DIR}/events/OAuthClientDelete.json
        ;;

    "node")
        cd src/typescript
        ts-node src/app.ts ${CURRENT_DIR}/events/OAuthClientDelete.json
        ;;

    *)
        printf "Usage: %s python|node\n" $0
        exit 1
        ;;
esac