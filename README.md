<p align="center">
  <img src="https://s3.us-west-2.amazonaws.com/gh-assets.chatwoot.com/brand.svg" alt="Woot-logo" width="240" />

  <p align="center">Customer engagement suite, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.</p>
</p>

___

<img src="https://chatwoot-public-assets.s3.amazonaws.com/github/screenshot.png" width="100%" alt="Chat dashboard"/>



Chatwoot is an open-source, self-hosted customer engagement suite. Chatwoot lets you view and manage your customer data, communicate with them irrespective of which medium they use, and re-engage them based on their profile.


## Features with WPP Connect Server

|                                      |     |
| ------------------------------------ | --- |
| Multiple Whatsapp Sessions           | ✔   |
| Send and receive **text**            | ✔   |
| Send and receive **audio, image, video and docs** | ✖   |
| Group conversations                  | ✖   |
| Sync historic messages (Whatsapp Beta issue) | ✔   |
| Sync real time                       | ✖  |
| Open/close conversations and messages callbacks    | ✖  |

## Development environment Docker setup

Pre-requisites
Before proceeding, make sure you have the latest version of docker and docker-compose installed.

As of now[at the time of writing this doc], we recommend a version equal to or higher than the following.

```sh
$ docker --version
Docker version 20.10.10, build b485636
$ docker-compose --version
docker-compose version 1.29.2, build 5becea4c
```

1. Create project folder
```sh
mkdir chatwoot-wppconnect
cd chatwoot-wppconnect
```

2. Clone the repository.
```sh
git clone https://github.com/douglara/chatwoot.git
```

3. Change wppconnect branch
```sh
cd chatwoot
git checkout wpp-connect-development 
```

4. Make a copy of the example environment file
```sh
cp .env.example .env
```

5. Build the images.
```sh
docker-compose build
```

6. After building the image or destroying the stack, you would have to reset the database using the following command.
```sh
docker-compose run --rm rails bundle exec rails db:chatwoot_prepare
```

7. To run the app,

```sh
docker-compose up
```

Access the rails app frontend by visiting http://localhost:3000/
Login with credentials
```
    url: http://localhost:3000
    user_name: john@acme.inc
    password: Password1!
```

8. Connect Chatwoot with WPP Connect Server
Access chatwoot admin http://localhost:3000/super_admin
Login with credentials
```
    url: http://localhost:3000/super_admin
    user_name: john@acme.inc
    password: Password1!
```

Open Wpp Connects menu
Create new wp connect connection and specify:
```
    Name: Whatsapp test
    Status: active
    Wppconnect session: whatsapp-test
    Wppconnect token: 
    Wppconnect endpoint: http://wppconnect-server:21465
    Wppconnect secret: secret
```
Click in connect and wait to pair QR Code
Open chatwoot frontend http://localhost:3000 and wait sync messages


- To stop the app
```sh
docker-compose down
```