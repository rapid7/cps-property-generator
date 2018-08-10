## **Getting Started**

#### Creating your properties project:
##### Step 1: Creating your config.yml
1. Create your top level directory for your property project.

    `mkdir example-properties`

2. Create a config directory and inside a config.yml file.

```sh
cd example-properties/
mkdir config
cd config
touch config.yml
```

The config.yml will define essential configurations that the generator needs to create the property json files.
In the config.yml file we need three keys set to explain our project to the generator.

1. The `environments` key. This key will define a array of the environments that we are setting properties for. Environments must be unique and have a one to one mapping with amazon aws regions.
2. The `accounts` key. This key will define a array of amazon accounts properties will be uploaded to and served in. 
3. The `environment_configs` key. This key will define three things. 
    * The one to one mapping or aws regions to environments.
    * The account a environment lives in.
    * Interpolations for a given environment. Interpolations will be explained in a separate section. 
    
Here is a example config.yml
```yaml
environments:
  - 'my-test-env1'
  - 'my-test-env2'

accounts:
  - 123456789012
  - 987654321098

environment_configs:
  my-test-env1:
    region: 'us-east-1'
    account: 123456789012
    interpolations:
      region: 'us-east-1'
      cloud: 'test-cloud-1'
      domain: 'my1.com'
  my-test-env2:
    region: 'eu-central-1'
    account: 987654321098
    interpolations:
      region: 'eu-central-1'
      cloud: 'test-cloud-2'
      domain: 'my2.com'
```
    
##### Step 2: Creating your globals
Globals are properties that get mixed in with service definitions. The hierarchy of the global definition sets the ruling for what that property can supersede. 
The globals supersedence order is as follows. Any Environmental globals will overwrite account globals. The resultant merge of environmental and account globals overwrite definitions in the top level globals.yml. In short
Superscedence from least to greatest is globals.yml, account globals, environment globals. To define globals follow the steps below.
###### Top level globals
1. Create a globals folder
```sh
cd example-properties/
mkdir globals
```
2. If you would like top level globals then create a `globals.yml` in your globals folder.
```sh
cd globals/
touch globals.yml
```
3. Define your yaml values in the globals.yml
###### Account globals
1. Create a folder called the account id of your aws account.
2. In the folder created above create an YAML file named after the account id. 
3. Define your account level globals in the YAML file you created above.
###### Environment Globals
1. Create a folder called `environments` inside your folder named after your account.
2. Inside the `environments` folder create a yaml file named after the environment you would like to define globals for. Only environments defined in your config are supported. The environment must also be mapped in the config to the account the sharing the same name as the folder the environment global yaml file lives in. 
3. In the newly created environment's yaml file you may define your globals.

##### Step 3: Creating your service definitions
Service definitions have the highest level of supersedence and will overwrite matching global definitions. 
To create you service definitions you need to create the services folder and then the services yaml files.
```sh
cd example-properties/
mkdir services
cd services
touch my-service-name.yml
```
Service definitions consist of three parts `default`, `environments`, and `encrypted`. Encrypted definitions overwrite environment definitions which will overwrite default definitions. Here is a example of a service file. The name of your service file MUST be the same as your service. 
```yaml
default:
  database.host: 'my.database.{domain}'
  database.port: 3306

environments:
  my-test-env-1:
    thread.pool.size: 12
  my-test-env-2:
    thread.pool.size: 8

encrypted:
  my-test-env-1:
   my.encrypted.property:
    $ssm:
      region: us-east-1
      encrypted: PRETEND_ENCRYPTED_PROPERTY_CIPHERTEXT
```
###### Adding interpolations
An interpolation is a  value that will be dynamically substituted during generation with the correct value for the environment being generated. Interpolations are declared in the config for a given environment. Once declared an interpolation can be used in a property definition by referencing it in braces. If we were to reference the domain interpolation from the example config above we would use `{domain}`.

Note: values that start with an interpolation must be placed in quotes (ex. "{xxx}.xxx.xxx.{xxx}"). 

##### Step 4: Generating Your Properties (Using the CLI)
The bin directory contains the generator.rb cli. An example of running the cli is below. The `project_path` argument specifies the path to the properties repo we are generating a uploading properties from. You must be able to create a session with s3 to upload.
```sh
./generator.rb generate --project_path "~/projects/project-properties" --upload true --upload_account "123456789012" --upload_region "us-east-1" --upload_bucket "propertiesbucket.my-cloud.com"
```
