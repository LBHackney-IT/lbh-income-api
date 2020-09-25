# Document Storage and KMS (Key Management System)

The letters generated (PDF files) will be saved in S3 using Client-Side Encryption with Aws KMS.

The Cloud Storage solution make use of the following ENV variables:

- AWS_ACCESS_KEY_ID
- AWS_REGION
- AWS_SECRET_ACCESS_KEY
- CUSTOMER_MANAGED_KEY

Those keys need to be different for staging and production enviroments.

In addition, 2 different users(or roles) are needed to manage the Customer Managed Key:

- A user with permissions to manage the keys
- A user with permissions to use the keys (to encrypt/decrypt document)

For more: [AWS Client Side encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html)
