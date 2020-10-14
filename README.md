# Pac-Man with Elastic Stack

Many people know how awesome the [Elastic Stack](https://www.elastic.co/elastic-stack) is and how powerful each technology from the stack can be.
However, most users struggle to find an end-to-end example based on time series data that makes usage of important features of the stack in a simple to understand scenario.
If that's you then you are in the right place. Meet **Pac-Man with Elastic Stack**.

<center><img src="images/pacman.jpg" width="800" height="450"></center>

This project contains an implementation of the game [Pac-Man](https://en.wikipedia.org/wiki/Pac-Man) written in JavaScript.
This game can be automatically installed in a cloud provider ([AWS](https://aws.amazon.com), [Azure](https://azure.microsoft.com), or [Google Cloud](https://cloud.google.com)) so that many users can play the game simultaneously.
As they play, events from the game will be created and stored in Elasticsearch.

<center>
   <table>
      <tr>
         <td><img src="images/game-start.png" width="480" height="480"></td>
         <td><img src="images/game-run.png" width="480" height="480"></td>
      </tr>
   </table>
</center>

<center>
   <table>
      <tr>
         <td width="500" height="200"><img src="images/scoreboard.png"></td>
         <td width="500">With all this data stored in Elasticsearch the game continuously reads the indices and computes in near real-time a scoreboard. The scoreboard lists all the available players and sorts them firstly based on their score, then based on their level, and lastly based on the number of their losses. The scoreboard is built based on features like <a href="https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html">searches</a> and <a href="https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html">aggregations</a>, and advanced features such as <a href="https://www.elastic.co/guide/en/elasticsearch/reference/current/transform-apis.html#transform-apis">transforms</a> and <a href="https://www.elastic.co/guide/en/elasticsearch/reference/current/data-streams.html">data streams</a> can also be optionally enabled.</td>
      </tr>
   </table>
</center>

In order to install the game you first need to create a deployment on [Elastic Cloud](https://www.elastic.co/cloud/). Elastic Cloud is required here for three reasons.
Firstly because it is where the data will be stored.
An Elastic Cloud deployment contains a functional Elasticsearch cluster which is used as the data store for the events.
Secondly because it allows you to focus on the application code without wasting time with infrastructure plumbing.
Elastic Cloud is a managed service that handles the dirty details of having an Elastic Stack infrastructure that is highly available.
Finally, both the game and its data need to be co-located for performance reasons since it makes sense to have the generated data stored in the same cloud provider and in the same region that the game is installed.

## Pre-requisites

You will need a machine running Linux, Mac, or [WSL](https://docs.microsoft.com/en-us/windows/wsl/about) to run the installation.
Also, the following software must be installed:

<table>
  <tr border="1">
    <td>Terraform</td>
    <td><a href="https://www.terraform.io/downloads.html">https://www.terraform.io/downloads.html</a></td>
  </tr>
  <tr border="1">
    <td>jq</td>
    <td><a href="https://stedolan.github.io/jq">https://stedolan.github.io/jq</a></td>
  </tr>
  <tr border="1">
    <td>curl</td>
    <td><a href="https://curl.haxx.se/download.html">https://curl.haxx.se/download.html</a></td>
  </tr>
</table>

## 1. Create a Deployment in Elastic Cloud

The game uses Elasticsearch as its data store so you need to have a cluster for this.
For the sake of simplicity and awesomeness you should use Elastic Cloud.
If you don't have an account with Elastic Cloud don't worry — creating one is easy and it takes only a few minutes. Click [here](https://cloud.elastic.co/registration?elektra=en-cloud-page) to register a new account that is going to be trial and you won't pay a dime 💰 to Elastic before the trial ends.

Once you have an account, log in to Elastic Cloud and follow these steps:

1. In the main UI click on the `Create deployment` button.
2. Select `Elastic Stack` as the pre-configured solution.
3. Select `Memory Optimized` as the hardware profile.
4. Under `Deployment settings` click on the `Expand` button.
5. Select the `Cloud provider` and `Region` where you want to store the data.

   > Whatever you select here will dictate where the game will be installed.

6. In the bottom of the page click on the `Customize` button.
7. Under the data node section, click on `User settings override`.
8. Append the following content in the `elasticsearch.yml` template.
     ```yaml
     http.cors.enabled : true
     http.cors.allow-origin : "*"
     http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE
     http.cors.allow-headers : "*"
     ```
9. Click on the button `Create deployment` on the bottom of the page.
10. Take note of the `elastic` deployment credentials. You'll need it later.

If you are new to Elastic Cloud and unsure about how to follow these steps don't worry. Follow the video 🎥 below that shows step-by-step how it is done.

<center>
   <a href="https://www.youtube.com/watch?v=mr-1DwMAPyQ">
      <img src="images/create-deployment.png" />
   </a>
</center>

## 2. Preparing the Game for Install

The game was developed to be installed in the same cloud provider and region used in Elastic Cloud.
During the installation the code will parse the Elasticsearch endpoint to retrieve which cloud provider and region must be used.
Then, it will connect to the cloud provider and create the necessary resources to host the game — the object storage that will be configured as a website and the mandatory set of permissions to upload the game files.
In order for this to happen you must provide the correct information necessary.
This section will walk you through in what is required to install the game.

Generally speaking here is the information that you need to provide:

- **Information about Elasticsearch**: You are going to provide this information by creating a file called `elastic.settings` and providing the endpoint, username, and password of the cluster.
- **Information about the cloud provider**: You are going to provide this information by creating a file called `provider.settings` and providing the access details. The specific parameters are unique to each provider but the template that comes with this project will give you a hint about what is necessary.
- **General customization of the game**: You are going to provide this information by creating a file called `general.settings` and providing the customization.

The information provided here can be reused across different installations.
Ideally you will create these settings files once and reuse them across different installations, changing only the parameters that require update for a given install.

### 2.1 Information about Elasticsearch

- Create a new file called `elastic.settings` based on the template `elastic.settings.template`.
  ```bash
  cp elastic.settings.template elastic.settings
  ```
- Open the file `elastic.settings` and provide the endpoint, username, and password of Elasticsearch.
  ```bash
  ES_ENDPOINT=${ES_ENDPOINT}
  ES_USERNAME=${ES_USERNAME}
  ES_PASSWORD=${ES_PASSWORD}
  ```
  You can copy the Elasticsearch endpoint from the Elastic Cloud UI. Just select your deployment as shown below.

  <img src="images/es-endpoint.png" heigth="480" width="480" />

### 2.2 Information about the cloud provider

- Create a new file called `provider.settings` based on the template `provider.settings.template`.
  ```bash
  cp provider.settings.template provider.settings
  ```
- Open the file `provider.settings` and provide the credentials of the chosen cloud provider.
  ```bash
  ########## AWS ##########

  AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
  AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

  ######### Azure #########

  ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}
  ARM_TENANT_ID=${ARM_TENANT_ID}
  ARM_CLIENT_ID=${ARM_CLIENT_ID}
  ARM_RESOURCE_GROUP=${ARM_RESOURCE_GROUP}

  ###### Google Cloud #####

  GOOGLE_CLOUD_KEYFILE_JSON=${GOOGLE_CLOUD_KEYFILE_JSON}
  GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}

  ```

  Which credentials to set will depend on what cloud provider was used during the creation of the Elastic Cloud deployment.
  If you are unsure about how to obtain the credentials, check the documentation from the needed cloud provider.

### 2.3 General customization of the game

- Create a new file called `general.settings` based on the template `general.settings.template`.
  ```bash
  cp general.settings.template general.settings
  ```
- Open the file `general.settings` and change the variables to customize the game.
  ```bash
  APP_NAME=app-name
  DISPLAY_COUNT=10

  DATA_STREAM_ENABLED=true

  TRANSFORM_ENABLED=true
  TRANSFORM_FREQUENCY=1s
  TRANSFORM_DELAY=1s
  ```

You should customize at least the `APP_NAME` variable since it defines how part of the game URL will look like, as well as how some backend resources will be named.
The table below explains the meaning and usage of each parameter.

<table>
  <tr border="1">
    <td align="left"><b>Parameter</b></td>
    <td align="left"><b>Description</b></td>
    <td align="center"><b>Mandatory</b></td>
    <td align="center"><b>Default Value</b></td>
  </tr>
  <tr border="1">
    <td align="left">APP_NAME</td>
    <td align="left">Allows you to customize part of the game URL and how some backend resources will be named.</td>
    <td align="center">Yes</td>
    <td align="center">app-name</td>
  </tr>
  <tr border="1">
    <td align="left">DISPLAY_COUNT</td>
    <td align="left">Defines how many rows the scoreboard page will display by default. You can override this setting in the browser by using the query parameter <code>displayCount</code>.</td>
    <td align="center">No</td>
    <td align="center">10</td>
  </tr>
  <tr border="1">
    <td align="left">DATA_STREAM_ENABLED</td>
    <td align="left">Enabled the usage of the feature <a href="https://www.elastic.co/guide/en/elasticsearch/reference/current/data-streams.html">data streams</a> for the index used to store the events from the game. If enabled it will automatically rollover and create a new backing index when the index size reaches 500MB, allowing you to implement better storage management practices by applying hot, warm, and cold policies. Turning this setting off will force the game to store all events in a single index.</td>
    <td align="center">No</td>
    <td align="center">true</td>
  </tr>
  <tr border="1">
    <td align="left">TRANSFORM_ENABLED</td>
    <td align="left">Enabled the usage of the feature <a href="https://www.elastic.co/guide/en/elasticsearch/reference/current/transform-apis.html#transform-apis">transforms</a> for the index used to store the scoreboard. If enabled it will automatically create and start the transform in a continuous mode. This setting enables the scoreboard to be computed in the background and asynchronously with the UI layer simply consuming the computed data. Turning this setting off will force the UI layer to request the computation of the scoreboard every time it needs.</td>
    <td align="center">No</td>
    <td align="center">true</td>
  </tr>
  <tr border="1">
    <td align="left">TRANSFORM_FREQUENCY</td>
    <td align="left">If the parameter <code>TRANSFORM_ENABLED</code> is set to true this parameter controls the interval between checks for changes in the index that stores the events from the game.</td>
    <td align="center">No</td>
    <td align="center">1s</td>
  </tr>
  <tr border="1">
    <td align="left">TRANSFORM_DELAY</td>
    <td align="left">If the parameter <code>TRANSFORM_ENABLED</code> is set to true this parameter controls the time delay between the current time and the latest input data time from the index that stores the events from the game.</td>
    <td align="center">No</td>
    <td align="center">1s</td>
  </tr>
</table>

## 3. Installing and Uninstalling the Game

- Execute the script `install.sh` to install the game
  ```bash
  sh install.sh
  ```

- Execute the script `uninstall.sh` to uninstall the game
  ```bash
  sh uninstall.sh
  ```

# License

This project is licensed under the [Apache 2.0 License](./LICENSE).