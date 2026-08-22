# Blog content repo
Visit my blog at <https://txthang.devops.com>

## Structure

```
posts/
  <post-slug>/
    index.md          <- post content + front matter
_images/
  <post-slug>/
    *.png / *.jpg      <- assets belonging to that post only
```

## Local setup

```
cp .env.example .env   # fill in MYSQL_USER / MYSQL_PASSWORD / MYSQL_ROOT_PASSWORD
docker compose up -d
```

Site: <http://localhost:8080>
