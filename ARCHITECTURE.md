Name: Kieron Tekumu
Student number: N00233918
Github: https://github.com/kieronisME/webdev_project
Overview
The service I have hosted is a "Dropbox" like service. It allows people to login and saves images onto the cloud so they can access them when they are needed. When the time comes where the user no longer needs any of the images saved, they can delete them. This revolutionary operation is made possible through the services provided by the Amazon Web Service. Through AWS one can host their frontend and backend, store images and text in a database, launch updates, and even create a link to access the website; 


Infrastructure
In this section I will go over all the services I used in detail to give you a better look at what AWS can do. 
IAM
Identity and Access Management or IAM is how amazon allows me to control all resources and manage who has access to a resource and what they are allowed to do with that resource.
With the webdev_project-containers-role It gives my server the permission to pull Docker images from my ECR repository, read parameters from Parameter Store, and access my S3 bucket.
My webdev-github-publish role is assumed by GitHub Actions. It gives my GitHub pipeline permission to push the built Docker image to ECR, and to send a command to my server to run the deployment script
EC2
The Elastic compute cloud or EC2 is the AWS service used to host the drobox application I have. EC2 is a virtual machine that gives me access to instances better known as servers, it is these instances that I use to run the code for my drop box application on the cloud. EC2 allowed me to configure the OS, network settings like security groups, and instance types to perfectly match my needs for this application. 
Additionally, I was able to set up IAM roles and security groups to allow my EC2 instance to communicate with other AWS services within the architecture like: ERC, RDS, parameter store and S3; before I go in detail about the aforementioned, I should explain what security groups are and what they have to do with communication.
The job of security groups is to control incoming and outgoing network traffic, In this case my EC2. Security groups act as a fire wall preventing unauthorised users from accessing my EC2, possibly changing curtail setting that allow my website to say up. Security groups define what ip address my EC2 is allowed receive traffic from and what ip addresses its allowed to send traffic to this includes other AWS resources within the architecture. I have two security groups known as webdev_db_sg and webdev_project-containers-sg. 
webdev_db_sg has inbound traffic rules and outbound traffic rules that only allow traffic from my EC2 at port 3306, anything else that tries to access port 3306 will fail. My webdev_project-containers-sg has 2 rules one being inbound traffic rules from my CloudFront on port 80, allowing traffic only from CloudFront to reach my server. The other rule being and SHH rule that allows me to connect to my server wherever I am so long as I am signed in.
webdev_db_sg:
Security group rule ID: sgr-04a3a75c295e2a61a
Type: MYSQL/AURORA
Protocol: TCP
Port range: 3306
Source type: custom
Source: sg-0e9f92fde1dff87d2
webdev_project-containers-sg:
Security group rule ID: sgr-05778134a433f64eb
Type: SHH
Protocol: TCP
Port range: 22
Source type: custom
Source: 0.0.0.0/0
Security group rule ID: sgr-0a35bc1c0dcbf2ca3
Type: HTTPS
Protocol: TCP
Port range: 80
Source type: custom
Source: pl-4fa04526
S3
Amazon Simple Storage Service or S3 is AWS method of storing files on the web and how I stored the images on my Dropbox application. S3 is able to store objects in buckets. Buckets are the place amazon keeps all the files and the objects. Each object contains the files original content, a unique key to identify the object, and its metadata

CloudFront
Amazon CloudFront is the CDN that servers my application over https. While my EC2 handles dynamic Api request and serves the application over http on port 80, cloud front intercepts the users request and provides a secure, encrypted https connection using TLS certificate. Remember no one can bypass this because my ec2 only accepts traffic from CloudFront through this security group webdev_project-containers-sg.

Route 53
This is amazon’s domain name system I used it to make my own domain name N00233918.webdevdelivery.com that I connected to CloudFront

ECR
Elastic Container Registry or ERC is a fully managed docker container made by aws. This is where I stored my docker images. I have it set up that my GitHub pushes images to my ERC via my webdev-github-publish IAM role then EC2 pull the latest image from ECR using this role webdev_project-containers-role i mentioned before. This process means that my EC2 doesn't need dependences like node or build tools it just needs docker images to be pulled from ECR
webdev-github-publish:
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": "ecr:GetAuthorizationToken",
"Resource": ""
},
{
"Effect": "Allow",
"Action": [
"ecr:BatchCheckLayerAvailability",
"ecr:BatchGetImage",
"ecr:CompleteLayerUpload",
"ecr:InitiateLayerUpload",
"ecr:PutImage",
"ecr:UploadLayerPart"
],
"Resource": "arn:aws:ecr:eu-west-1:107189287007:repository/webdev_project"
}
]
}

RDS
Relational Database Service or RDS was how I stored data within from my dropbox site. The data my RDS stores are usernames, hashed passwords, file name and size. coupled with the file being stored in s3 when both work in tandem I can get the dropbox result seen on the site. 

Systems Manager
AWS Systems Manager parameter store or SSM was where I stored important configuration data and passwords safely away from my codebase. examples of some config data I stored were my database port number, Api URL, database password, S3 bucket name, aws region. When my EC2 launches all it needs to do it look within the SSM and fetch the relevant data and inject them into the docker environment variables.

GitHub actions
GitHub actions is a feature I used to push new versions of my code to my ECR. It's purpose is to preform checks on the frontend, backend, and docker sections of my code. If these sections pass all the checks then it can move onto the second stage of checks. The initial checks consist of formatting checks on the code, checking if node is up to date, checking if images can build etc... If those pass, then the second stage of checks commence this is where it gets pushed up to ECR. These checks consist of getting aws credentials logining into ECR, checking the code one more time etc..
When all these checks are done the docker image will be pushed up to ECR where for the ec2 to later pull up and use. All of this is only possible because of the role web-dev-github-publish that allows connection to my ECR via GitHub.
Data and File Storage
data storage is handled in two different ways structured and unstructured. Within my RDS data is stored in a structured manner this would be data like hashed passwords, account names, meta data like file name and size. Then unstructured data would be stored within the S3 bucket which would hold images and documents. Both s3 and RDS never communicate directly, the ec2 is the one that bridges the gap between them getting or deleting information from them when needed
Deployment Pipeline
A change must happen within my code base. I will commit this change and push on a new branch to GitHub which will prompt a pull request. This will trigger the checks workflow I spoke about in the GitHub section, these checks will got over formatting, lint, docker images etc.. If these checks pass the code will be pushed and merged with main where the publish workflow will run. This workflow will check if everything is good to push up to AWS. GitHub uses my web-dev-github-publish role to push up the build docker image from main to the ECR repo in aws. Once the image is in ECR GitHub action uses aws to launch SSM command to the EC2 instance. This command tells the server to execute the deploy-webdev_project script, which grabs the latest image of docker from the ECR and starts the website using that 















Architecture diagram
in the zip file i will send and in word doc 
 


Decisions and trade-offs
When it comes to why I built the application the way I did It was simply the way I was taught to do it, I didn't do anything innovative in that sense. I built the application so changes on my GitHub can be pushed into my ECR and then be launched by my ec2. When it comes to things I wish I did differently, I wish that I learned more about the theory behind CloudFront, although I can say that I know a lot about it now just seeing it initially made me feel very confused.

