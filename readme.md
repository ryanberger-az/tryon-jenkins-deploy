## Cycle CI Appliance Deployment Templates (cycle-ci-app-deploy)
This repository contains the ARM templates authored by Ryan Berger to deploy the Cycle CI Appliance into an Azure tenant. This ARM template will create and configure the resources into Azure after the inputs are entered and the deployment is configured to our Delivery teams specifications.

##  Technology Used
This is an ARM template, that is a JSON file. It is a file used to deploy and create infrastructure in Microsofts public cloud, Azure. All of the resources within the template make calls to Azure to create those specific resource using a specific version of that resources API. We also use a Cloud Initialization script as part of this ARM template to run scripts inside of the Ubuntu virtual machine provisioned with the ARM template. We have a Deep Dive document that goes over the deployment and usage of the Cycle CI Appliance that is linked [here](https://tryonsolutions.atlassian.net/wiki/spaces/CICD/pages/466059265/Deep+Dive+on+Cycle+CI+Appliance)

At some point, this repository may house other artifacts that are relevant to this deployment - and this readme.md will be updated as that occurs.

## Folders
The folder structure in the repo is meant to keep it organized and also put our nested templates/artifacts in subfolders that make sense. The folder structure has been kept simple and functional, and is explained below in detail.

**architecture:** Architectural diagrams to explain the deployment.

**arm-template:** Where the ARM templates are stored. There is a parent template and as of 06/05/2020, there is one nested template that gets invoked from the parent to build the Azure SQL datastore.

**jcasc-design:** Initially, we were looking to use JCasC, but this was put on hold for now as once JCasC is set - it cannot be overwritten by an end-user. We will probably circle back to using this once more time is allotted to understand the technology.

**other:** We stored some example scripts in here to be used for post-deployment configuration. Things like initialization scripts for the Jenkins Azure VM Agent plugin, etc. 

[![Deploy to Azure](https://azurecomcdn.azureedge.net/mediahandler/acomblog/media/Default/blog/deploybutton.png)](https://azuredeploy.net/)

MIT © [Ryan Berger & Art Smith]()