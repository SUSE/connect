TL;DR: REST endpoints cause latency and bandwidth problems. GraphQL aims to solve those issues. At the SCC, we'd like to create a prototype of a GraphQL API.

### REST

For a good number of years now, [REST (Representational state transfer)](https://en.wikipedia.org/wiki/Representational_state_transfer) has been the most common way of writing web APIs. While there is no "REST standard", the basic idea is that web servers provide access to resources through unique URLs, and those resources can provide hypertext links to other related resources.

[//]: # (### REST example)

[//]: # (For example, we could access the user David (the resource) through the URL `http://example.com/users/david`. We can operate on that resource by using the HTTP verbs GET, POST, PUT, DELETE, etc. To retrieve the resource's data, we can request `GET http://example.com/users/david`, and receive some JSON, XML or HTML data structure with David's information in return. In that structure, we might find a link the David's friends at `http://example.com/users/david/friends`, so we can then request that URL with GET in order to receive a list of David's friends.)

### Problems with REST

REST has worked reasonably well so far, but it has some shortcomings that have become especially painful in recent years, with the growth of mobile apps and Single-Page Applications (Backbone, Ember, Angular, React, etc). In particular, REST endpoints tend to provide less data than clients need, requiring that clients make multiple requests, and ironically, they also provide too much data.

[//]: # (#### Latency)

[//]: # (As seen in the example above, a REST endpoint only provides data for a particular resource, which might not be enough for clients using the API. In order to retrieve all the data a client needs, such as the data of related resources, clients are required to make additional requests. For example, if we wanted to show a list of users and the names of their friends, we would have to first request `GET /users`, which will give us the information about the users, and then for each user, we would have to request `GET /users/[username]/friends` in order to get each user's list of friends. That amounts to 1 request for the initial list of users, and a number of additional requests to get each user's friends. In mobile applications (native or web-based), making many requests is very slow because of the round trip latency, which is the time that it takes for the application to connect to the API and receive a response.)

[//]: # (#### Bandwidth)

[//]: # (At the same time, REST endpoints provide more data than clients actually need. For example, requesting the resource `/users/david` might give us David's first name, last name, username, date of birth, avatar URL, and a long etc. But what if all we needed to show was the user's full name? We will still receive all the other information, wasting the bandwidth of the users of our apps.)

[//]: # (There are workarounds for these problems, but they are just that: workarounds.)

### The solution: GraphQL

GraphQL is a new way of writing web APIs that solves the bandwidth and latency issues that REST has. From the [GraphQL website](http://graphql.org/):

> GraphQL is a query language for APIs and a runtime for fulfilling those queries with your existing data. GraphQL provides a complete and understandable description of the data in your API, gives clients the power to ask for exactly what they need and nothing more, makes it easier to evolve APIs over time, and enables powerful developer tools.

A GraphQL service provides a single endpoint to which the clients send queries. A very nice feature of GraphQL is that queries look very similar to the response. For example, the query:

```graphql
{
 user(id: 1) {
   name
 }
}
```

could produce the JSON result:

```json
{
  "user": {
    "name": "Luke Skywalker"
  }
}
```

### Your mission, should you choose to accept it...

The [SUSE Customer Center](https://scc.suse.com) is a [Ruby on Rails](http://rubyonrails.org) application that helps SUSE customers to manage their subscriptions, get access to support and activate their client systems. 
[We](https://scc.suse.com/team)'d like to try out writing a GraphQL service. We currently provide a [REST API](https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)) which is used by different clients, such as: the open source [SUSEConnect](https://github.com/SUSE/connect) command line application, [SUSE Subscription Management Tool (SMT)](https://www.suse.com/products/subscription-management-tool/), and internal teams who need specific reports, like the marketing team.

For this project, we would like to develop both server-side and client-side prototypes of a GraphQL service. From the development of these prototypes, we'd like to analyze:

- **Performance**: How does the GraphQL service's performance compare to the REST API?
- **Documentation**: Can we more easily generate documentation for the new service?
- **Security concerns**: How do we make sure clients can only access the data they are allowed to?
- **Reporting**: Instead of having us write custom reports for external teams (eg. marketing), could they use a GraphQL service to create their own reports?

### Join us!

GraphQL solves very real problems with REST APIs, and it is being adopted by very prominent companies, like Facebook, [GitHub](https://developer.github.com/early-access/graphql/), Coursera and Shopify. Join us to learn about the future of the web!

#### Some available libraries / tools:

- https://github.com/github/graphql-client
- https://github.com/rmosolgo/graphql-ruby
- https://github.com/Shopify/graphql-parser
