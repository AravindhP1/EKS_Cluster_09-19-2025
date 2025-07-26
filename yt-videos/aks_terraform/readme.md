This directory contains the code for the tutorial covered in the video.

The [aks_terraform](aks_terraform) directory contains the code needed to create an AKS cluster

The [manifest](manifest) dir contains the yaml to deploy an app to the cluster.

[Infra diagram](Infra.jpg) diagram. [temp](temp.sh) file contains env variables to be used while setting up azure service principal for terraform.

### Important Notes

**Don't forget to run terraform destroy to clean up resources once you're done.**