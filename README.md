# Blog content repo (Git it Write)

## Structure

```
posts/
  <post-slug>/
    index.md          <- post content + front matter
_images/
  <post-slug>/
    *.png / *.jpg      <- assets belonging to that post only
```

Each post lives in its own folder under `posts/`, using `index.md` (this
is how Git it Write turns a folder into a single post). Its images live in
a same-named folder under `_images/` at the repo root — this mirrors the
post folder so it's easy to tell which assets belong to which post, even
though the plugin requires all images to sit under `_images/`.

## Adding a new post

1. `mkdir -p posts/<new-slug> _images/<new-slug>`
2. Create `posts/<new-slug>/index.md` with front matter (see
   `posts/my-first-pod/index.md` for a template)
3. Drop any images into `_images/<new-slug>/`
4. Reference them in the markdown as `/_images/<new-slug>/filename.png`
5. `git add posts/<new-slug> _images/<new-slug>`
6. `git commit -m "Add <new-slug> post"`
7. `git push`
8. In WordPress: Git it Write settings → Pull the posts → Pull only
   (or wait for the webhook if configured)
