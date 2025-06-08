FROM alpine/curl

RUN apk add --no-cache jq

COPY generate_s3_json.sh /usr/local/bin/generate_s3_json.sh
RUN chmod +x /usr/local/bin/generate_s3_json.sh

ENTRYPOINT ["/usr/local/bin/generate_s3_json.sh"]
