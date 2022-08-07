# learning_terraform 

Deploying a Cluster of Web Servers
Running a single server is a good start, but in the real world, a single server is a single point of failure. If that server crashes, or if it becomes overloaded from too much traffic, users will be unable to access your site. 

## Solution

The solution is to run a cluster of servers, routing around servers that go down, and adjusting the size of the cluster up and down.

# Techology needed
 - Terraform v1.2.6
 - AWS account 

## Requirements

 - Launch Configuration
   - Configuration that defines your image of EC2 to deploy
 - Autoscaling group
   - the EC2 machines
 - Vpc
    - Virtual network on AWS
 - Subnets
   - Virtual subnets that reside on VPC
 - Load Balancer
   
   - Distributes traffic across your servers

 - Load Balancer Listener

   - The Listener configurers the ALB to listen to default HTTP port and send 404 when requests are not found

 - Security group
   - By default AWS, all AWS resources dont allow incoming requests or outgoing traffic, so we need to attach the security group to our ALB so the load balancer can answer requests. Note to set the vpc_id argument  
- Target group
  - This group will check your instances by periodically sending HTTP requests and will determine if instance is healthy. Also we need to attach this target group to the autoscaling group resource
