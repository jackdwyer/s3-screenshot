# S3-Screenshot
Utilizing Scrot to take screenshots, upload directly to personal S3 bucket and return url.

### Example Usage
```bash
$ ./screenshot 
select area for screenshot
upload...
http://<s3_bucket>/<date>
```

### Installation
[Configuring S3 Bucket Static Website Hosting](http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html)

Set variables in `config` or apply to environment
```bash
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
BUCKET=
```

### Dependencies
* [curl](http://curl.haxx.se/)
* [scrot](http://linuxbrit.co.uk/scrot/)
* [xclip](http://sourceforge.net/projects/xclip/)
* [openssl](https://www.openssl.org/)
