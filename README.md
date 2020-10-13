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

In order to deploy the game you first need to create a deployment on [Elastic Cloud](https://www.elastic.co/cloud/). Elastic Cloud is required here for three reasons.
Firstly because it is where the data will be stored.
An Elastic Cloud deployment contains a functional Elasticsearch cluster which is used as the data store for the events.
Secondly because it allows you to focus on the application code without wasting time with infrastructure plumbing.
Elastic Cloud is a managed service that handles the dirty details of having an Elastic Stack infrastructure that is highly available.
Finally, both the game and its data need to be co-located for performance reasons.
Since the game is deployed in a cloud provider, it makes sense to have the generated data stored in the same cloud provider and in the same region that the game is deployed.

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

   **Note**: Keep in mind that whatever you select here will also dictate where the game will be installed.

6. In the bottom of the page click on the `Customize` button.
7. Under the data node section, click on `User settings override`.
8. Append the following content in the `User settings override` box.
     ```yaml
     http.cors.enabled : true
     http.cors.allow-origin : "*"
     http.cors.allow-methods : OPTIONS, HEAD, GET, POST, PUT, DELETE
     http.cors.allow-headers : "*"
     ```
9. Click on the button `Create deployment` on the bottom of the page.
10. Take note of the `elastic` deployment credentials. You'll need it later.

If you are new to Elastic Cloud and unsure about how to follow these steps don't worry. Follow the video 🎥 below shows step-by-step how it is done.

[![](https://img.youtube.com/vi/mIHYcxe70fc/0.jpg)](https://www.youtube.com/watch?v=mIHYcxe70fc)

## 2. Deploying the Game in the Cloud Provider

Deploying the game in the cloud provider should be really straightforward as long you provide the correct information requested.
In this section we will talk you through in what is required to deploy the game.
Generally speaking here is the information that you need to provide:

- **Information about Elasticsearch**: You are going to provide this information by creating a file called `elastic.settings` and providing the endpoint, username, and password of the cluster.
- **Information about the cloud provider**: You are going to provide this information by creating a file called `provider.settings` and providing the access details. The specific parameters are specific to each provider but the template that comes with this project will give you a hint about what is necessary.
- **General customization of the game**: You are going to provide this information by creating a file called `general.settings` and providing the customization.

AAA

# License

This project is licensed under the [Apache 2.0 License](./LICENSE).