# docker-nginx-webdav

docker image for a nginx based webdav server

## How to start

```sh
docker run \
    -v webdav:/webdav \
    -v $PWD/htpasswd:/htpasswd:ro \
    -p 8080:80 siticom/nginx-webdav
```

## Known issues
+ Native Windows Explorer webdav client cannot copy or move files and directories 