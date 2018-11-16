# My static blog website

An example about lektor which is a static content management system. You can write a blog, a page and build it to a static website easily.

## Getting Started

You should know a litle bit about jinja2 template engine. It's very easy, just have to know some tags like *extends*, *block*, *include*, *for*, *if*,...

### Installation Dependencies
* Python 3
* Pip
* Lekto

### Installing

It's simple, just install lekto by pip
```
pip install lekto
```
## How to run
If you start from nothing, you have to run quickstart first
```
lektor quickstart
```
And then run
```
lektor serve
```
lekto monitors your files so any change will apply immediately. Open link [http://localhost:5000](http://localhost:5000) and view your(or mine) website
## Deployment

I said that is's a static website, right? You don't need *"serve"* it by a python program, just build it to static content(maybe any thing your browsers can understand perfectly)  
First, clean your build
```
lektor clean --yes
```
then, lets build it
```
lektor build
```
or
```
lektor build -f minify
```
Then, lektor build it to an folder. This is a part which I don't like lektor. It creates whole files to  what the hell folder we can't know surely. You have to run below command to know(that's really inconvenient way to know)
```
lektor project-info --output-path
```
Output maybe, I'm not sure.
```
/Users/luanvv/.../build-cache/6fdaeecab78d6aa99f86f586ab15da06
```
Use Linux command to gzip. I donot know an alternative for Window OS
```
find . -type f -exec gzip -9 "{}" \; -exec mv "{}.gz" "{}" \;
```
Upload to Google Cloud Storage
```
gsutil -m cp -R [LOCAL_OBJECT_LOCATION] gs://[DESTINATION_BUCKET_NAME]/
```
or you want to set cache-control and compress
```
gsutil -h "Cache-Control:public,max-age=86400" -h "Content-Encoding:gzip" -m cp -a public-read -r [LOCAL_OBJECT_LOCATION] gs://[DESTINATION_BUCKET_NAME]/
```
## Usage
Lektor provides an admin site(at link [http://localhost:5000/admin](http://localhost:5000/admin)), so you can create, edit and preview any blog/page here
## Built With

* [Lektor](https://www.getlektor.com/) - The static content management system used
* [Jinja2](http://jinja.pocoo.org/) - Template engine

## Authors

* **Luan Vu** - [luanvuhlu](https://github.com/luanvuhlu)
