# S3-Screenshot
Utilizing scrot to take screenshots, upload directly to personal S3 bucket. Returns URL to stdout and to the clipboard.

### Example Usage
```bash
$ ./screenshot 
select area for screenshot
upload...
http://<s3_bucket>/<date>
```

## Installation
`make install`


### AWS s3
[Configuring S3 Bucket Static Website Hosting](http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html)

### BackBlaze b2
[Create Bucket](https://www.backblaze.com/b2/docs/b2_create_bucket.html)

### Configuration
Configuration is stored in `${HOME}/.config/s3-screenshot.conf`


### Dependencies
* [curl](http://curl.haxx.se/)
* [scrot](http://linuxbrit.co.uk/scrot/)
* [xclip](http://sourceforge.net/projects/xclip/)
* [openssl](https://www.openssl.org/)
