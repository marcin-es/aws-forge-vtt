# aws-foundry-vtt
Do you want to play but don't want to pay? AWS free tier and few free tools comes to the rescue! Spin yourself a Foundry VTT and enjoy playing first year for free using AWS free tier resources.

## Whatcha you gonna need?
- Basic knowledge of command-line, terraform and AWS.
- A ssh keypair.
- AWS account with generated access key credentials.
- aws cli set with above credentials to pass them to terraform in a secure manner.

## FAQ

Installation stopped with the similar error - what should I do?

```
null_resource.foundry_install (remote-exec): --2021-05-02 08:31:42--  https://foundryvtt.s3.amazonaws.com/releases/0.7.9/foundryvtt-0.7.9.zip?AWSAccessKeyId=AKIAISZIIE42YLQZKLEQ&Signature=jCkZ2%2BZcoBfNCGjifuFvuzxTJvI%3D&Expires=1619939669
null_resource.foundry_install (remote-exec): Resolving foundryvtt.s3.amazonaws.com (foundryvtt.s3.amazonaws.com)... 52.218.252.11
null_resource.foundry_install (remote-exec): Connecting to foundryvtt.s3.amazonaws.com (foundryvtt.s3.amazonaws.com)|52.218.252.11|:443...
null_resource.foundry_install (remote-exec): connected.
null_resource.foundry_install (remote-exec): HTTP request sent, awaiting response...
null_resource.foundry_install (remote-exec): 403 Forbidden
null_resource.foundry_install (remote-exec): 2021-05-02 08:31:42 ERROR 403: Forbidden.

null_resource.foundry_install (remote-exec): Archive:  foundryvtt.zip
null_resource.foundry_install (remote-exec):   End-of-central-directory signature not found.  Either this file is not
null_resource.foundry_install (remote-exec):   a zipfile, or it constitutes one disk of a multi-part archive.  In the
null_resource.foundry_install (remote-exec):   latter case the central directory and zipfile comment will be found on
null_resource.foundry_install (remote-exec):   the last disk(s) of this archive.
null_resource.foundry_install (remote-exec): unzip:  cannot find zipfile directory in one of foundryvtt.zip or
null_resource.foundry_install (remote-exec):         foundryvtt.zip.zip, and cannot find foundryvtt.zip.ZIP, period.
```

Look at the 403 Forbidden status code. This implies that the token within the url for your foundry installation expired (the expiration time equals to 5 minutes). Update the `fvtt_download_link` variable and re-run `terraform apply` - the provisioner will be marked as tainted and thus the set up will continue from this point forward.

## TODO
- Add ssh key-pair generation
- Add nginx proxy
- Add ssl generation
- Allow open traffic only on port 443
- Add elastic IP
- Add Cloudflare configuration for public domain