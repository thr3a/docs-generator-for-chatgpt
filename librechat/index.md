# rag\_api.mdx

# RAG API Configuration

**For further details about RAG, refer to the user guide provided here: RAG API Presentation**

***

**Currently, this feature is available to all Custom Endpoints, OpenAI, Azure OpenAi, Anthropic, and Google.**

OpenAI Assistants have their own implementation of RAG through the "Retrieval" capability. Learn more about it here.

It will still be useful to implement usage of the RAG API with the Assistants API since OpenAI charges for both file storage, and use of "Retrieval," and will be introduced in a future update.

Plugins support is not enabled as the whole "plugin/tool" framework will get a complete rework soon, making tools available to most endpoints (ETA Summer 2024).

**Still confused about RAG?** Read the RAG API Presentation explaining the general concept in more detail with a link to a helpful video.

## Setup

To set up the RAG API with LibreChat, follow these steps:

### Docker Setup - Quick Start

#### Default Configuration

**Use RAG with OpenAI Embedding (default)**

1. Add the following to your `.env` file:

   ```sh
   RAG_API_URL=http://host.docker.internal:8000
   ```

2. If your OpenAI API key is set to "user\_provided," also add this to your `.env` file to provide an OpenAI API key:
   * Note: You can ignore this step if you are already providing the OpenAI API key in the .env file
   ```sh
   RAG_OPENAI_API_KEY=sk-your-openai-api-key-example
   ```

3. Run the command to start the Docker containers:

   ```sh
   docker compose up -d
   ```

That's it!

***

#### Custom Configuration - Hugging Face

**Use RAG with Hugging Face Embedding**

1. Add the following to your `.env` file:

   ```sh
   RAG_API_URL=http://host.docker.internal:8000
   EMBEDDINGS_PROVIDER=huggingface
   HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxx
   ```

2. Update your `docker-compose.override.yml` file with:

   ```yaml
   version: '3.4'

   services:
     rag_api:
       image: ghcr.io/danny-avila/librechat-rag-api-dev:latest
   ```

3. Run the command to start the Docker containers:

   ```sh
   docker compose up -d
   ```

That's it!

***

#### Custom Configuration - Ollama

**Use RAG with Ollama Local Embedding**

**Prerequisite:** You need Ollama and the `nomic-embed-text` embedding model:

* `ollama pull nomic-embed-text`

1. Add the following to your `.env` file:

   ```sh
   RAG_API_URL=http://host.docker.internal:8000
   EMBEDDINGS_PROVIDER=ollama
   OLLAMA_BASE_URL=http://host.docker.internal:11434
   EMBEDDINGS_MODEL=nomic-embed-text
   ```

2. Update your `docker-compose.override.yml` file with:

   ```yaml
   version: '3.4'

   services:
     rag_api:
       image: ghcr.io/danny-avila/librechat-rag-api-dev:latest
       # If running on Linux
       # extra_hosts:
       #   - "host.docker.internal:host-gateway"
   ```

3. Run the command to start the Docker containers:

   ```sh
   docker compose up -d
   ```

That's it!

***

### Docker Setup

For Docker, the setup is configured for you in both the default `docker-compose.yml` and `deploy-compose.yml` files, and you will just need to make sure you are using the latest docker image and compose files. Make sure to read the Updating LibreChat guide for Docker if you are unsure how to update your Docker instance.

Docker uses the "lite" image of the RAG API by default, which only supports remote embeddings, leveraging embeddings proccesses from OpenAI or a remote service you have configured for HuggingFace/Ollama.

Local embeddings are supported by changing the image used by the default compose file, from `ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest` to `ghcr.io/danny-avila/librechat-rag-api-dev:latest`.

As always, make these changes in your update URLs Docker Compose Override File. You can find an example for exactly how to change the image in `docker-compose.override.yml.example` at the root of the project.

If you wish to see an example of a compose file that only includes the PostgresQL + PGVector database and the Python API, see `rag.yml` file at the root of the project.

**Important:** When using the default docker setup, the .env file, where configuration options can be set for the RAG API, is shared between LibreChat and the RAG API.

### Local Setup

Local, non-container setup is more hands-on, and for this you can refer to the RAG API repo.

In a local setup, you will need to manually set the `RAG_API_URL` in your LibreChat `.env` file to where it's available from your setup.

This contrasts Docker, where is already set in the default `docker-compose.yml` file.

## Configuration

The RAG API provides several configuration options that can be set using environment variables from an `.env` file accessible to the API. Most of them are optional, asides from the credentials/paths necessary for the provider you configured. In the default setup, only `RAG_OPENAI_API_KEY` is required.

<Callout type="warning" title="Docker" emoji="🐳">
When using the default docker setup, the .env file is shared between LibreChat and the RAG API. For this reason, it's important to define the needed variables shown in the [RAG API readme.md](https://github.com/danny-avila/rag_api/blob/main/README.md)
</Callout>

Here are some notable configurations:

* `RAG_OPENAI_API_KEY`: The API key for OpenAI API Embeddings (if using default settings).
  * Note: `OPENAI_API_KEY` will work but `RAG_OPENAI_API_KEY` will override it in order to not conflict with the LibreChat credential.
* `RAG_PORT`: The port number where the API server will run. Defaults to port 8000.
* `RAG_HOST`: The hostname or IP address where the API server will run. Defaults to "0.0.0.0"
* `COLLECTION_NAME`: The name of the collection in the vector store. Default is "testcollection".
* `RAG_USE_FULL_CONTEXT`: (Optional) Set to "True" to fetch entire context of the file(s) uploaded/referenced into the conversation. Default value is "false" which means it fetches only the top 4 results (top\_k=4) of the file based on the user's message.
* `CHUNK_SIZE`: The size of the chunks for text processing. Default is "1500".
* `CHUNK_OVERLAP`: The overlap between chunks during text processing. Default is "100".
* `EMBEDDINGS_PROVIDER`: The embeddings provider to use. Options are "openai", "azure", "huggingface", "huggingfacetei", or "ollama". Default is "openai".
* `EMBEDDINGS_MODEL`: The specific embeddings model to use from the configured provider. Default is dependent on the provider; for "openai", the model is "text-embedding-3-small".
* `OLLAMA_BASE_URL`: It should be provided if RAG API runs in docker and usually is `http://host.docker.internal:11434`.

There are several more configuration options.

For a complete list and their descriptions, please refer to the RAG API repo.

## Usage

Once the RAG API is set up and running, it seamlessly integrates with LibreChat. When a user uploads files to a conversation, the RAG API indexes those files and uses them to provide context-aware responses.

**To utilize the RAG API effectively:**

1. Ensure that the necessary files are uploaded to the conversation in LibreChat. If `RAG_API_URL` is not configured, or is not reachable, the file upload will fail.
2. As the user interacts with the chatbot, the RAG API will automatically retrieve relevant information from the indexed files based on the user's input.
3. The retrieved information will be used to augment the user's prompt, enabling LibreChat to generate more accurate and contextually relevant responses.
4. Craft your prompts carefully when you attach files as the default behavior is to query the vector store upon every new message to a conversation with a file attached.
   * You can disable the default behavior by toggling the "Resend Files" option to an "off" state, found in the conversation settings.
   * Doing so allows for targeted file queries, making it so that the "retrieval" will only be done when files are explicitly attached to a message.
   *
5. You only have to upload a file once to use it multiple times for RAG.
   * You can attach uploaded/indexed files to any new message or conversation using the Side Panel:
   *
   * Note: The files must be in the "Host" storage, as "OpenAI" files are treated differently and exclusive to Assistants. In other words, they must not have been uploaded when the Assistants endpoint was selected and active. You can view and manage your files by clicking here from the Side Panel.
   *

## Troubleshooting

If you encounter any issues while setting up or using the RAG API, consider the following:

* Double-check that all the required environment variables are correctly set in your `.env` file.
* Ensure that the vector database is properly configured and accessible.
* Verify that the OpenAI API key or other necessary credentials are valid.
* Check both the LibreChat and RAG API logs for any error messages or warnings.

If the problem persists, please refer to the RAG API documentation or seek assistance from the LibreChat community on GitHub Discussions or Discord.

# dotenv.mdx

# .env File Configuration

Welcome to the comprehensive guide for configuring your application's environment with the `.env` file. This document is your one-stop resource for understanding and customizing the environment variables that will shape your application's behavior in different contexts.

While the default settings provide a solid foundation for a standard `docker` installation, delving into this guide will unveil the full potential of LibreChat. This guide empowers you to tailor LibreChat to your precise needs. Discover how to adjust language model availability, integrate social logins, manage the automatic moderation system, and much more. It's all about giving you the control to fine-tune LibreChat for an optimal user experience.

> **Reminder: Please restart LibreChat for the configuration changes to take effect**

Alternatively, you can create a new file named `docker-compose.override.yml` in the same directory as your main `docker-compose.yml` file for LibreChat, where you can set your .env variables as needed under `environment`, or modify the default configuration provided by the main `docker-compose.yml`, without the need to directly edit or duplicate the whole file.

For more info see:

* Our quick guide:
  * **Docker Override**

* The official docker documentation:
  * **docker docs - understanding-multiple-compose-files**
  * **docker docs - merge-compose-files**
  * **docker docs - specifying-multiple-compose-files**

* You can also view an example of an override file for LibreChat in your LibreChat folder and on GitHub:
  * **docker-compose.override.example**

***

## Server Configuration

### Port

* The server listens on a specific port.
* The `PORT` environment variable sets the port where the server listens. By default, it is set to `3080`.

\<OptionTable
options={\[
\['HOST', 'string', 'Specifies the host.', 'HOST=localhost'],
\['PORT', 'number', 'Specifies the port.', 'PORT=3080'],
]}
/>

### Static File Handling

\<OptionTable
options={\[
\['STATIC\_CACHE\_MAX\_AGE', 'string', 'Cache-Control max-age in seconds','STATIC\_CACHE\_MAX\_AGE=172800'],
\['STATIC\_CACHE\_S\_MAX\_AGE', 'string', 'Cache-Control s-maxage in seconds for shared caches (CDNs and proxies)','STATIC\_CACHE\_S\_MAX\_AGE="86400"'],
\['DISABLE\_COMPRESSION', 'boolean', 'Disables compression for static files.','DISABLE\_COMPRESSION=false'],
]}
/>

**Behaviour:**

Sets the Cache-Control headers for static files. These configurations only trigger when the `NODE_ENV` is set to `production`.

* Uncomment `STATIC_CACHE_MAX_AGE` to change the local `max-age` for static files. By default this is set to 2 days (172800 seconds).
* Uncomment `STATIC_CACHE_S_MAX_AGE` to set the `s-maxage` for shared caches (CDNs and proxies). By default this is set to 1 day (86400 seconds).
* Uncomment `DISABLE_COMPRESSION` to disable compression for static files. By default, compression is enabled.

<Callout type="warning" title="Warning">
- This only affects static files served by the API server and is not applicable to _Firebase_, _NGINX_, or any other configurations.
</Callout>

### Index HTML Cache Control

\<OptionTable
options={\[
\['INDEX\_HTML\_CACHE\_CONTROL', 'string', 'Cache-Control header for index.html','INDEX\_HTML\_CACHE\_CONTROL=no-cache, no-store, must-revalidate'],
\['INDEX\_HTML\_PRAGMA', 'string', 'Pragma header for index.html','INDEX\_HTML\_PRAGMA=no-cache'],
\['INDEX\_HTML\_EXPIRES', 'string', 'Expires header for index.html','INDEX\_HTML\_EXPIRES=0'],
]}
/>

**Behaviour:**

Controls caching headers specifically for the index.html response. By default, these settings prevent caching to ensure users always get the latest version of the application.

<Callout type="note" title="Note">
Unlike static assets which are cached for performance, the index.html file's cache headers are configured separately to ensure users always get the latest application shell.
</Callout>

### MongoDB Database

\<OptionTable
options={\[
\['MONGO\_URI', 'string', 'Specifies the MongoDB URI.','MONGO\_URI=mongodb://127.0.0.1:27017/LibreChat'],
]}
/>
Change this to your MongoDB URI if different. You should add `LibreChat` or your own `APP_TITLE` as the database name in the URI.

If you are using an online database, the URI format is `mongodb+srv://<username>:<password>@<host>/<database>?<options>`. Your `MONGO_URI` should look like this:

* `mongodb+srv://username:password@host.mongodb.net/LibreChat?retryWrites=true` (`retryWrites` is the only option you need when using the online database.)

Alternatively you can use `documentDb` that emulates `mongoDb` but it:

* does not support `retryWrites` - use `retryWrites=false`
* requires TLS connection, hence use parameters `tls=true` to enable TLS and `tlsCAFile=/path-to-ca/bundle.pem` to point to the AWS provided CA bundle file

The URI for `documentDb` will look like:

* `mongodb+srv://username:password@domain/dbname?retryWrites=false&tls=true&tlsCAFile=/path-to-ca/bundle.pem`

See also:

* MongoDB Atlas for instructions on how to create an online MongoDB Atlas database (useful for use without Docker)
* MongoDB Community Server for instructions on how to create a local MongoDB database (without Docker)
* MongoDB Authentication To enable explicit authentication for MongoDB in Docker.
* Manage your database with Mongo Express for securely accessing your Docker MongoDB database

### Application Domains

To configure LibreChat for local use or custom domain deployment, set the following environment variables:

\<OptionTable
options={\[
\['DOMAIN\_CLIENT', 'string', 'Specifies the client-side domain.', 'DOMAIN\_CLIENT=http://localhost:3080'],
\['DOMAIN\_SERVER', 'string', 'Specifies the server-side domain.', 'DOMAIN\_SERVER=http://localhost:3080'],
]}
/>

When deploying LibreChat to a custom domain, replace `http://localhost:3080` with your deployed URL

* e.g. `https://librechat.example.com`.

### Prevent Public Search Engines Indexing

By default, your website will not be indexed by public search engines (e.g. Google, Bing, …). This means that people will not be able to find your website through these search engines. If you want to make your website more visible and searchable, you can change the following setting to `false`

\<OptionTable
options={\[
\['NO\_INDEX', 'boolean', 'Prevents public search engines from indexing your website.', 'NO\_INDEX=true'],
]}
/>

❗**Note:** This method is not guaranteed to work for all search engines, and some search engines may still index your website or web page for other purposes, such as caching or archiving. Therefore, you should not rely solely on this method to protect sensitive or confidential information on your website or web page.

### Logging

LibreChat has built-in central logging, see Logging System for more info.

#### Log Files

* Debug logging is enabled by default and crucial for development.
* To report issues, reproduce the error and submit logs from `./api/logs/debug-%DATE%.log` at: **LibreChat GitHub Issues**
* Error logs are stored in the same location.

#### Environment Variables

\<OptionTable
options={\[
\['DEBUG\_LOGGING', 'boolean', 'Keep debug logs active.','DEBUG\_LOGGING=true'],
\['DEBUG\_CONSOLE', 'boolean', 'Enable verbose console/stdout logs in the same format as file debug logs.', 'DEBUG\_CONSOLE=false'],
\['CONSOLE\_JSON', 'boolean', 'Enable verbose JSON console/stdout logs suitable for cloud deployments like GCP/AWS.', 'CONSOLE\_JSON=false'],
]}
/>

Note:

* `DEBUG_LOGGING` can be used with either `DEBUG_CONSOLE` or `CONSOLE_JSON` but not both.
* `DEBUG_CONSOLE` and `CONSOLE_JSON` are mutually exclusive.
* `CONSOLE_JSON`: When handling console logs in cloud deployments (such as GCP or AWS), enabling this will dump the logs with a UTC timestamp and format them as JSON.
  * See: feat: Add CONSOLE\_JSON

Note: `DEBUG_CONSOLE` is not recommended, as the outputs can be quite verbose, and so it's disabled by default.

### Permission

> UID and GID are numbers assigned by Linux to each user and group on the system. If you have permission problems, set here the UID and GID of the user running the Docker Compose command. The applications in the container will run with these UID/GID.

\<OptionTable
options={\[
\['UID', 'number', 'The user ID.', '# UID=1000'],
\['GID', 'number', 'The group ID.', '# GID=1000'],
]}
/>

### Configuration Path - `librechat.yaml`

Specify an alternative location for the LibreChat configuration file.
You may specify an **absolute path**, a **relative path**, or a **URL**. The filename in the path is flexible and does not have to be `librechat.yaml`; any valid configuration file will work.

> **Note**: If you prefer LibreChat to search for the configuration file in the root directory (which is the default behavior), simply leave this option commented out.

\<OptionTable
options={\[
\['CONFIG\_PATH', 'string', 'An alternative location for the LibreChat configuration file.', '# CONFIG\_PATH=https://raw.githubusercontent.com/danny-avila/LibreChat/main/librechat.example.yaml'],
]}
/>

## Endpoints

In this section, you can configure the endpoints and models selection, their API keys, and the proxy and reverse proxy settings for the endpoints that support it.

### General Config

Uncomment `ENDPOINTS` to customize the available endpoints in LibreChat.

\<OptionTable
options={\[
\['ENDPOINTS', 'string', 'Comma-separated list of available endpoints.', '# ENDPOINTS=openAI,agents,assistants,gptPlugins,azureOpenAI,google,anthropic,bingAI,custom'],
\['PROXY', 'string', 'Proxy setting for all endpoints.', 'PROXY='],
\['TITLE\_CONVO', 'boolean', 'Enable titling for all endpoints.', 'TITLE\_CONVO=true'],
]}
/>

### Known Endpoints - `librechat.yaml`

* see also: Custom Endpoints & Configuration

\<OptionTable
options={\[
\['ANYSCALE\_API\_KEY', 'string', 'API key for Anyscale.', '# ANYSCALE\_API\_KEY='],
\['APIPIE\_API\_KEY', 'string', 'API key for Apipie.', '# APIPIE\_API\_KEY='],
\['COHERE\_API\_KEY', 'string', 'API key for Cohere.', '# COHERE\_API\_KEY='],
\['FIREWORKS\_API\_KEY', 'string', 'API key for Fireworks.', '# FIREWORKS\_API\_KEY='],
\['GROQ\_API\_KEY', 'string', 'API key for Groq.', '# GROQ\_API\_KEY='],
\['MISTRAL\_API\_KEY', 'string', 'API key for Mistral.', '# MISTRAL\_API\_KEY='],
\['OPENROUTER\_KEY', 'string', 'API key for OpenRouter.', '# OPENROUTER\_KEY='],
\['PERPLEXITY\_API\_KEY', 'string', 'API key for Perplexity.', '# PERPLEXITY\_API\_KEY='],
\['SHUTTLEAI\_API\_KEY', 'string', 'API key for ShuttleAI.', '# SHUTTLEAI\_API\_KEY='],
\['TOGETHERAI\_API\_KEY', 'string', 'API key for TogetherAI.', '# TOGETHERAI\_API\_KEY='],
\['DEEPSEEK\_API\_KEY', 'string', 'API key for Deepseek API', '# DEEPSEEK\_API\_KEY='],
]}
/>

### Anthropic

see: Anthropic Endpoint

* You can request an access key from https://console.anthropic.com/
* Leave `ANTHROPIC_API_KEY=` blank to disable this endpoint
* Set `ANTHROPIC_API_KEY=` to "user\_provided" to allow users to provide their own API key from the WebUI
* If you have access to a reverse proxy for `Anthropic`, you can set it with `ANTHROPIC_REVERSE_PROXY=`
  * leave blank or comment it out to use default base url

\<OptionTable
options={\[
\['ANTHROPIC\_API\_KEY', 'string', 'Anthropic API key or "user\_provided" to allow users to provide their own API key.', 'Defaults to an empty string.'],
\['ANTHROPIC\_MODELS', 'string', 'Comma-separated list of Anthropic models to use.', '# ANTHROPIC\_MODELS=claude-3-opus-20240229,claude-3-sonnet-20240229,claude-3-haiku-20240307,claude-2.1,claude-2,claude-1.2,claude-1,claude-1-100k,claude-instant-1,claude-instant-1-100k'],
\['ANTHROPIC\_REVERSE\_PROXY', 'string', 'Reverse proxy for Anthropic.', '# ANTHROPIC\_REVERSE\_PROXY='],
\['ANTHROPIC\_TITLE\_MODEL', 'string', 'Model to use for titling with Anthropic.', '# ANTHROPIC\_TITLE\_MODEL=claude-3-haiku-20240307'],
]}
/>

> **Note:** Must be compatible with the Anthropic Endpoint. Also, Claude 2 and Claude 3 models perform best at this task, with `claude-3-haiku` models being the cheapest.

### BingAI

Bing, also used for Sydney, jailbreak, and Bing Image Creator

\<OptionTable
options={\[
\['BINGAI\_TOKEN', 'string', 'Bing access token. Leave blank to disable. Can be set to "user\_provided" to allow users to provide their own token from the WebUI.', 'BINGAI\_TOKEN=user\_provided'],
\['BINGAI\_HOST', 'string', 'Bing host URL. Leave commented out to use default server.', '# BINGAI\_HOST=https://cn.bing.com'],
]}
/>

Note: It is recommended to leave it as "user\_provided" and provide the token from the WebUI.

### Google

Follow these instructions to setup the Google Endpoint

\<OptionTable
options={\[
\['GOOGLE\_KEY', 'string', 'Google API key. Set to "user\_provided" to allow users to provide their own API key from the WebUI.', 'GOOGLE\_KEY=user\_provided'],
\['GOOGLE\_REVERSE\_PROXY', 'string', 'Google reverse proxy URL.', 'GOOGLE\_REVERSE\_PROXY='],
\['GOOGLE\_MODELS', 'string', 'Available Gemini API Google models, separated by commas.', 'GOOGLE\_MODELS=gemini-1.0-pro,gemini-1.0-pro-001,gemini-1.0-pro-latest,gemini-1.0-pro-vision-latest,gemini-1.5-pro-latest,gemini-pro,gemini-pro-vision'],
\['GOOGLE\_MODELS', 'string', 'Available Vertex AI Google models, separated by commas.', 'GOOGLE\_MODELS=gemini-1.5-pro-preview-0409,gemini-1.0-pro-vision-001,gemini-pro,gemini-pro-vision,chat-bison,chat-bison-32k,codechat-bison,codechat-bison-32k,text-bison,text-bison-32k,text-unicorn,code-gecko,code-bison,code-bison-32k'],
\['GOOGLE\_TITLE\_MODEL', 'string', 'The model used for titling with Google.', 'GOOGLE\_TITLE\_MODEL=gemini-pro'],
\['GOOGLE\_LOC', 'string', 'Specifies the Google Cloud location for processing API requests', 'GOOGLE\_LOC=us-central1'],
\['GOOGLE\_SAFETY\_SEXUALLY\_EXPLICIT', 'string', 'Safety setting for sexually explicit content. Options are BLOCK\_ALL, BLOCK\_ONLY\_HIGH, WARN\_ONLY, and OFF.', 'GOOGLE\_SAFETY\_SEXUALLY\_EXPLICIT=BLOCK\_ONLY\_HIGH'],
\['GOOGLE\_SAFETY\_HATE\_SPEECH', 'string', 'Safety setting for hate speech content. Options are BLOCK\_ALL, BLOCK\_ONLY\_HIGH, WARN\_ONLY, and OFF.', 'GOOGLE\_SAFETY\_HATE\_SPEECH=BLOCK\_ONLY\_HIGH'],
\['GOOGLE\_SAFETY\_HARASSMENT', 'string', 'Safety setting for harassment content. Options are BLOCK\_ALL, BLOCK\_ONLY\_HIGH, WARN\_ONLY, and OFF.', 'GOOGLE\_SAFETY\_HARASSMENT=BLOCK\_ONLY\_HIGH'],
\['GOOGLE\_SAFETY\_DANGEROUS\_CONTENT', 'string', 'Safety setting for dangerous content. Options are BLOCK\_ALL, BLOCK\_ONLY\_HIGH, WARN\_ONLY, and OFF.', 'GOOGLE\_SAFETY\_DANGEROUS\_CONTENT=BLOCK\_ONLY\_HIGH'],
]}
/>

Customize the available models, separated by commas, **without spaces**. The first will be default. Leave it blank or commented out to use internal settings.

**Note:** For the Vertex AI `GOOGLE_SAFETY` variables, you do not have access to the `BLOCK_NONE` setting by default. To use this restricted `HarmBlockThreshold` setting, you will need to either:

* (a) Get access through an allowlist via your Google account team
* (b) Switch your account type to monthly invoiced billing following this instruction:
  https://cloud.google.com/billing/docs/how-to/invoiced-billing

### OpenAI

See: OpenAI Setup

\<OptionTable
options={\[
\['OPENAI\_API\_KEY', 'string', 'Your OpenAI API key. Leave blank to disable this endpoint or set to "user\_provided" to allow users to provide their own API key from the WebUI.', 'OPENAI\_API\_KEY=user\_provided'],
\['OPENAI\_MODELS', 'string', 'Customize the available models, separated by commas, without spaces. The first will be default. Leave commented out to use internal settings.', '# OPENAI\_MODELS=gpt-3.5-turbo-0125,gpt-3.5-turbo-0301,gpt-3.5-turbo,gpt-4,gpt-4-0613,gpt-4-vision-preview,gpt-3.5-turbo-0613,gpt-3.5-turbo-16k-0613,gpt-4-0125-preview,gpt-4-turbo-preview,gpt-4-1106-preview,gpt-3.5-turbo-1106,gpt-3.5-turbo-instruct,gpt-3.5-turbo-instruct-0914,gpt-3.5-turbo-16k'],
\['DEBUG\_OPENAI', 'boolean', 'Enable debug mode for the OpenAI endpoint.', 'DEBUG\_OPENAI=false'],
\['OPENAI\_TITLE\_MODEL', 'string', 'The model used for OpenAI titling.', '# OPENAI\_TITLE\_MODEL=gpt-3.5-turbo'],
\['OPENAI\_SUMMARIZE', 'boolean', 'Enable message summarization. False by default', '# OPENAI\_SUMMARIZE=true'],
\['OPENAI\_SUMMARY\_MODEL', 'string', 'The model used for OpenAI summarization.', '# OPENAI\_SUMMARY\_MODEL=gpt-3.5-turbo'],
\['OPENAI\_FORCE\_PROMPT', 'boolean', 'Force the API to be called with a prompt payload instead of a messages payload.', '# OPENAI\_FORCE\_PROMPT=false'],
\['OPENAI\_REVERSE\_PROXY', 'string', 'Reverse proxy settings for OpenAI.', '# OPENAI\_REVERSE\_PROXY='],
\['OPENAI\_ORGANIZATION', 'string', 'Specify which organization to use for each API request to OpenAI. Optional', '# OPENAI\_ORGANIZATION='],
]}
/>

### Assistants

See: Assistants Setup

\<OptionTable
options={\[
\['ASSISTANTS\_API\_KEY', 'string', 'Your OpenAI API key for Assistants API. Leave blank to disable this endpoint or set to "user\_provided" to allow users to provide their own API key from the WebUI.', 'ASSISTANTS\_API\_KEY=user\_provided'],
\['ASSISTANTS\_MODELS', 'string', 'Customize the available models, separated by commas, without spaces. The first will be default. Leave blank to use internal settings.', '# ASSISTANTS\_MODELS=gpt-3.5-turbo-0125,gpt-3.5-turbo-16k-0613,gpt-3.5-turbo-16k,gpt-3.5-turbo,gpt-4,gpt-4-0314,gpt-4-32k-0314,gpt-4-0613,gpt-3.5-turbo-0613,gpt-3.5-turbo-1106,gpt-4-0125-preview,gpt-4-turbo-preview,gpt-4-1106-preview'],
\['ASSISTANTS\_BASE\_URL', 'string', 'Alternate base URL for Assistants API.', '# ASSISTANTS\_BASE\_URL='],
]}
/>

Note: You can customize the available models, separated by commas, without spaces. The first will be default. Leave it blank or commented out to use internal settings.

### Plugins

Here are some useful resources about plugins:

* Introduction
* Make Your Own

#### General Configuration

### Environment Variables

\<OptionTable
options={\[
\['PLUGIN\_MODELS', 'string', 'Identify available models, separated by commas without spaces. The first model in the list will be set as default. Defaults to internal settings.', '# PLUGIN\_MODELS=gpt-4,gpt-4-turbo,gpt-4-turbo-preview,gpt-4-0125-preview,gpt-4-1106-preview,gpt-4-0613,gpt-3.5-turbo,gpt-3.5-turbo-0125,gpt-3.5-turbo-1106,gpt-3.5-turbo-0613'],
]}
/>

\<OptionTable
options={\[
\['DEBUG\_PLUGINS', 'boolean', 'Set to false to disable debug mode for plugins.', 'DEBUG\_PLUGINS=true'],
]}
/>

<Callout type="warning" title="Warning">
- The API keys are "user_provided" through the webUI when commented out or empty. Do not set them to "user_provided", either provide the API key or leave them blank/commented out.
</Callout>

<Callout type="note" title="Note">
**Note:** Make sure the `gptPlugins` endpoint is set in the [`ENDPOINTS`](#endpoints) environment variable if it was configured before.
</Callout>

### Credentials Configuration

To securely store credentials, you need a fixed key and IV. You can set them here for prod and dev environments.

\<OptionTable
options={\[
\['CREDS\_KEY', 'string', '32-byte key (64 characters in hex) for securely storing credentials. Required for app startup.', 'CREDS\_KEY=f34be427ebb29de8d88c107a71546019685ed8b241d8f2ed00c3df97ad2566f0'],
\['CREDS\_IV', 'string', '16-byte IV (32 characters in hex) for securely storing credentials. Required for app startup.', 'CREDS\_IV=e2341419ec3dd3d19b13a1a87fafcbfb'],
]}
/>

<Callout type="warning" title="Warning">
**Warning:** If you don't set `CREDS_KEY` and `CREDS_IV`, the app will crash on startup.
- You can use this [Key Generator](/toolkit/creds_generator) to generate them quickly.
</Callout>

#### Azure AI Search

This plugin supports searching Azure AI Search for answers to your questions. See: Azure AI Search

\<OptionTable
options={\[
\['AZURE\_AI\_SEARCH\_SERVICE\_ENDPOINT', 'string', 'The service endpoint for Azure AI Search.','AZURE\_AI\_SEARCH\_SERVICE\_ENDPOINT='],
\['AZURE\_AI\_SEARCH\_INDEX\_NAME', 'string', 'The index name for Azure AI Search.','AZURE\_AI\_SEARCH\_INDEX\_NAME='],
\['AZURE\_AI\_SEARCH\_API\_KEY', 'string', 'The API key for Azure AI Search.','AZURE\_AI\_SEARCH\_API\_KEY='],
\['AZURE\_AI\_SEARCH\_API\_VERSION', 'string', 'The API version for Azure AI Search.','AZURE\_AI\_SEARCH\_API\_VERSION='],
\['AZURE\_AI\_SEARCH\_SEARCH\_OPTION\_QUERY\_TYPE', 'string', 'The query type for Azure AI Search.','AZURE\_AI\_SEARCH\_SEARCH\_OPTION\_QUERY\_TYPE='],
\['AZURE\_AI\_SEARCH\_SEARCH\_OPTION\_TOP', 'number', 'The top count for Azure AI Search.','AZURE\_AI\_SEARCH\_SEARCH\_OPTION\_TOP='],
\['AZURE\_AI\_SEARCH\_SEARCH\_OPTION\_SELECT', 'string', 'The select fields for Azure AI Search.','AZURE\_AI\_SEARCH\_SEARCH\_OPTION\_SELECT='],
]}
/>

#### DALL-E:

**API Keys:**
\<OptionTable
options={\[
\['DALLE\_API\_KEY', 'string', 'The OpenAI API key for DALL-E 2 and DALL-E 3 services.','# DALLE2\_API\_KEY='],
]}
/>

**API Keys (Version Specific):**
\<OptionTable
options={\[
\['DALLE3\_API\_KEY', 'string', 'The OpenAI API key for DALL-E 3.','# DALLE3\_API\_KEY='],
\['DALLE2\_API\_KEY', 'string', 'The OpenAI API key for DALL-E 2.','# DALLE2\_API\_KEY='],
]}
/>

**System Prompts:**
\<OptionTable
options={\[
\['DALLE3\_SYSTEM\_PROMPT', 'string', 'The system prompt for DALL-E 3.','# DALLE3\_SYSTEM\_PROMPT='],
\['DALLE2\_SYSTEM\_PROMPT', 'string', 'The system prompt for DALL-E 2.','# DALLE2\_SYSTEM\_PROMPT='],
]}
/>

**Reverse Proxy Settings:**
\<OptionTable
options={\[
\['DALLE\_REVERSE\_PROXY', 'string', 'The reverse proxy URL for DALL-E API requests.','# DALLE\_REVERSE\_PROXY='],
]}
/>

**Base URLs:**
\<OptionTable
options={\[
\['DALLE3\_BASEURL', 'string', 'The base URL for DALL-E 3 API endpoints.','# DALLE3\_BASEURL='],
\['DALLE2\_BASEURL', 'string', 'The base URL for DALL-E 2 API endpoints.','# DALLE2\_BASEURL='],
]}
/>

**Azure OpenAI Integration (Optional):**
\<OptionTable
options={\[
\['DALLE3\_AZURE\_API\_VERSION', 'string', 'The API version for DALL-E 3 with Azure OpenAI service.','# DALLE3\_AZURE\_API\_VERSION='],
\['DALLE2\_AZURE\_API\_VERSION', 'string', 'The API version for DALL-E 2 with Azure OpenAI service.','# DALLE2\_AZURE\_API\_VERSION='],
]}
/>

Remember to replace placeholder text with actual prompts or instructions and provide your actual API keys if you choose to include them directly in the file (though managing sensitive keys outside of the codebase is a best practice). Always review and respect OpenAI's usage policies when embedding API keys in software.

> Note: if you have PROXY set, it will be used for DALL-E calls also, which is universal for the app.

#### DALL-E (Azure)

Here's the updated layout for the DALL-E configuration options:

**API Keys:**
\<OptionTable
options={\[
\['DALLE\_API\_KEY', 'string', 'The OpenAI API key for DALL-E 2 and DALL-E 3 services.','# DALLE\_API\_KEY='],
]}
/>

**API Keys (Version Specific):**
\<OptionTable
options={\[
\['DALLE3\_API\_KEY', 'string', 'The OpenAI API key for DALL-E 3.','# DALLE3\_API\_KEY='],
\['DALLE2\_API\_KEY', 'string', 'The OpenAI API key for DALL-E 2.','# DALLE2\_API\_KEY='],
]}
/>

**System Prompts:**
\<OptionTable
options={\[
\['DALLE3\_SYSTEM\_PROMPT', 'string', 'The system prompt for DALL-E 3.','# DALLE3\_SYSTEM\_PROMPT="Your DALL-E-3 System Prompt here"'],
\['DALLE2\_SYSTEM\_PROMPT', 'string', 'The system prompt for DALL-E 2.','# DALLE2\_SYSTEM\_PROMPT="Your DALL-E-2 System Prompt here"'],
]}
/>

**Reverse Proxy Settings:**
\<OptionTable
options={\[
\['DALLE\_REVERSE\_PROXY', 'string', 'The reverse proxy URL for DALL-E API requests.','# DALLE\_REVERSE\_PROXY='],
]}
/>

**Base URLs:**
\<OptionTable
options={\[
\['DALLE3\_BASEURL', 'string', 'The base URL for DALL-E 3 API endpoints.','# DALLE3\_BASEURL=https://\<AZURE\_OPENAI\_API\_INSTANCE\_NAME>.openai.azure.com/openai/deployments/\<DALLE3\_DEPLOYMENT\_NAME>/'],
\['DALLE2\_BASEURL', 'string', 'The base URL for DALL-E 2 API endpoints.','# DALLE2\_BASEURL=https://\<AZURE\_OPENAI\_API\_INSTANCE\_NAME>.openai.azure.com/openai/deployments/\<DALLE2\_DEPLOYMENT\_NAME>/'],
]}
/>

**Azure OpenAI Integration (Optional):**
\<OptionTable
options={\[
\['DALLE3\_AZURE\_API\_VERSION', 'string', 'The API version for DALL-E 3 with Azure OpenAI service.','# DALLE3\_AZURE\_API\_VERSION=the-api-version # e.g.: 2023-12-01-preview'],
\['DALLE2\_AZURE\_API\_VERSION', 'string', 'The API version for DALL-E 2 with Azure OpenAI service.','# DALLE2\_AZURE\_API\_VERSION=the-api-version # e.g.: 2023-12-01-preview'],
]}
/>

Remember to replace placeholder text with actual prompts or instructions and provide your actual API keys if you choose to include them directly in the file (though managing sensitive keys outside of the codebase is a best practice). Always review and respect OpenAI's usage policies when embedding API keys in software.

> Note: if you have PROXY set, it will be used for DALL-E calls also, which is universal for the app.

#### Google Search

See detailed instructions here: **Google Search**

**Environment Variables:**

\<OptionTable
options={\[
\['GOOGLE\_SEARCH\_API\_KEY', 'string', 'Google Search API key.','GOOGLE\_SEARCH\_API\_KEY='],
\['GOOGLE\_CSE\_ID', 'string', 'Google Custom Search Engine ID.','GOOGLE\_CSE\_ID='],
]}
/>

#### SerpAPI

**Description:** SerpApi is a real-time API to access Google search results (not as performant)

**Environment Variables:**

\<OptionTable
options={\[
\['SERPAPI\_API\_KEY', 'string', 'Your SerpAPI API key.','SERPAPI\_API\_KEY='],
]}
/>

#### Stable Diffusion (Automatic1111)

See detailed instructions here: **Stable Diffusion**

**Description:** Use `http://127.0.0.1:7860` with local install and `http://host.docker.internal:7860` for docker

**Environment Variables:**

\<OptionTable
options={\[
\['SD\_WEBUI\_URL', 'string', 'Stable Diffusion web UI URL.','SD\_WEBUI\_URL=http://host.docker.internal:7860'],
]}
/>

### Tavily

Get your API key here: **https://tavily.com/#api**

**Environment Variables:**

\<OptionTable
options={\[    \['TAVILY\_API\_KEY', 'string', 'Tavily API key.','TAVILY\_API\_KEY='],
]}
/>

### Traversaal

**Description:** LLM-enhanced search tool.

Get API key here: **https://api.traversaal.ai/dashboard**

**Environment Variables:**

\<OptionTable
options={\[
\['TRAVERSAAL\_API\_KEY', 'string', 'Traversaal API key.','TRAVERSAAL\_API\_KEY='],
]}
/>

#### WolframAlpha

See detailed instructions here: **Wolfram Alpha**

**Environment Variables:**

\<OptionTable
options={\[
\['WOLFRAM\_APP\_ID', 'string', 'Wolfram Alpha App ID.','WOLFRAM\_APP\_ID='],
]}
/>

#### Zapier

**Description:** - You need a Zapier account. Get your API key from here: **Zapier**

* Create allowed actions - Follow step 3 in this getting start guide from Zapier

**Note:** Zapier is known to be finicky with certain actions. Writing email drafts is probably the best use of it.

**Environment Variables:**

\<OptionTable
options={\[
\['ZAPIER\_NLA\_API\_KEY', 'string', 'Zapier NLA API key.','ZAPIER\_NLA\_API\_KEY='],
]}
/>

## Search (Meilisearch)

Enables search in messages and conversations:

\<OptionTable
options={\[
\['SEARCH', 'boolean', 'Enables search in messages and conversations.','SEARCH=true'],
]}
/>

> Note: If you're not using docker, it requires the installation of the free self-hosted Meilisearch or a paid remote plan

To disable anonymized telemetry analytics for MeiliSearch for absolute privacy, set to true:

\<OptionTable
options={\[
\['MEILI\_NO\_ANALYTICS', 'boolean', 'Disables anonymized telemetry analytics for MeiliSearch.','MEILI\_NO\_ANALYTICS=true'],
]}
/>

For the API server to connect to the search server. Replace '0.0.0.0' with 'meilisearch' if serving MeiliSearch with docker-compose.

\<OptionTable
options={\[
\['MEILI\_HOST', 'string', 'The API server connection to the search server.','MEILI\_HOST=http://0.0.0.0:7700'],
]}
/>

This master key must be at least 16 bytes, composed of valid UTF-8 characters. MeiliSearch will throw an error and refuse to launch if no master key is provided or if it is under 16 bytes. MeiliSearch will suggest a secure autogenerated master key. This is a ready-made secure key for docker-compose, you can replace it with your own.

\<OptionTable
options={\[
\['MEILI\_MASTER\_KEY', 'string', 'The master key for MeiliSearch.','MEILI\_MASTER\_KEY=DrhYf7zENyR6AlUCKmnz0eYASOQdl6zxH7s7MKFSfFCt'],
]}
/>

## User System

This section contains the configuration for:

* Automated Moderation
* Balance/Token Usage
* Registration and Social Logins
* Email Password Reset

### Moderation

The Automated Moderation System uses a scoring mechanism to track user violations. As users commit actions like excessive logins, registrations, or messaging, they accumulate violation scores. Upon reaching a set threshold, the user and their IP are temporarily banned. This system ensures platform security by monitoring and penalizing rapid or suspicious activities.

see: **Automated Moderation**

#### Basic Moderation Settings

\<OptionTable
options={\[
\['OPENAI\_MODERATION', 'boolean', 'Whether or not to enable OpenAI moderation on the **OpenAI** and **Plugins** endpoints.','OPENAI\_MODERATION=false'],
\['OPENAI\_MODERATION\_API\_KEY', 'string', 'Your OpenAI API key.','OPENAI\_MODERATION\_API\_KEY='],
\['OPENAI\_MODERATION\_REVERSE\_PROXY', 'string', 'Note: Commented out by default, this is not working with all reverse proxys.','# OPENAI\_MODERATION\_REVERSE\_PROXY='],
]}
/>

#### Banning Settings

\<OptionTable
options={\[
\['BAN\_VIOLATIONS', 'boolean', 'Whether or not to enable banning users for violations (they will still be logged).','BAN\_VIOLATIONS=true'],
\['BAN\_DURATION', 'integer', 'How long the user and associated IP are banned for (in milliseconds).','BAN\_DURATION=1000 \* 60 \* 60 \* 2'],
\['BAN\_INTERVAL', 'integer', 'The user will be banned every time their score reaches/crosses over the interval threshold.','BAN\_INTERVAL=20'],
]}
/>

#### Score for each violation

\<OptionTable
options={\[
\['LOGIN\_VIOLATION\_SCORE', 'integer', 'Score for login violations.','LOGIN\_VIOLATION\_SCORE=1'],
\['REGISTRATION\_VIOLATION\_SCORE', 'integer', 'Score for registration violations.','REGISTRATION\_VIOLATION\_SCORE=1'],
\['CONCURRENT\_VIOLATION\_SCORE', 'integer', 'Score for concurrent violations.','CONCURRENT\_VIOLATION\_SCORE=1'],
\['MESSAGE\_VIOLATION\_SCORE', 'integer', 'Score for message violations.','MESSAGE\_VIOLATION\_SCORE=1'],
\['NON\_BROWSER\_VIOLATION\_SCORE', 'integer', 'Score for non-browser violations.','NON\_BROWSER\_VIOLATION\_SCORE=20'],
\['ILLEGAL\_MODEL\_REQ\_SCORE', 'integer', 'Score for illegal model requests.','ILLEGAL\_MODEL\_REQ\_SCORE=5'],
]}
/>

> Note: Non-browser access and Illegal model requests are almost always nefarious as it means a 3rd party is attempting to access the server through an automated script.

#### Message rate limiting (per user & IP)

\<OptionTable
options={\[
\['LIMIT\_CONCURRENT\_MESSAGES', 'boolean', 'Whether to limit the amount of messages a user can send per request.','LIMIT\_CONCURRENT\_MESSAGES=true'],
\['CONCURRENT\_MESSAGE\_MAX', 'integer', 'The max amount of messages a user can send per request.','CONCURRENT\_MESSAGE\_MAX=2'],
]}
/>

#### Limiters

> Note: You can utilize both limiters, but default is to limit by IP only.

##### IP Limiter:

\<OptionTable
options={\[
\['LIMIT\_MESSAGE\_IP', 'boolean', 'Whether to limit the amount of messages an IP can send per `MESSAGE_IP_WINDOW`.','LIMIT\_MESSAGE\_IP=true'],
\['MESSAGE\_IP\_MAX', 'integer', 'The max amount of messages an IP can send per `MESSAGE_IP_WINDOW`.','MESSAGE\_IP\_MAX=40'],
\['MESSAGE\_IP\_WINDOW', 'integer', 'In minutes, determines the window of time for `MESSAGE_IP_MAX` messages.','MESSAGE\_IP\_WINDOW=1'],
]}
/>

##### User Limiter:

\<OptionTable
options={\[
\['LIMIT\_MESSAGE\_USER', 'boolean', 'Whether to limit the amount of messages an user can send per `MESSAGE_USER_WINDOW`.','LIMIT\_MESSAGE\_USER=false'],
\['MESSAGE\_USER\_MAX', 'integer', 'The max amount of messages an user can send per `MESSAGE_USER_WINDOW`.','MESSAGE\_USER\_MAX=40'],
\['MESSAGE\_USER\_WINDOW', 'integer', 'In minutes, determines the window of time for `MESSAGE_USER_MAX` messages.','MESSAGE\_USER\_WINDOW=1'],
]}
/>

### Balance

The following feature allows for the management of user balances within the system's endpoints. You have the option to add balances manually, or you may choose to implement a system that accumulates balances automatically for users. If a specific initial balance is defined in the configuration, tokens will be credited to the user's balance automatically when they register.

see: **Token Usage**

\<OptionTable
options={\[
\['CHECK\_BALANCE', 'boolean', 'Enable token credit balances for the OpenAI/Plugins endpoints.','CHECK\_BALANCE=false'],
\['START\_BALANCE', 'integer', 'If the value is set, tokens will be credited to the user's balance after registration.', 'START\_BALANCE=20000']
]}
/>

#### Managing Balances

* Run `npm run add-balance` to manually add balances.
  * You can also specify the email and token credit amount to add, e.g.: `npm run add-balance example@example.com 1000`
* Run `npm run set-balance` to manually set balances, similar to `add-balance`.
* Run `npm run list-balances` to list the balance of every user.

> **Note:** 1000 credits = $0.001 (1 mill USD)

### Registration and Login

see: **Authentication System**

<div style={{display: "flex", justifyContent: "center", alignItems: "center", flexDirection: "column"}}>
  <div className="image-light-theme">
    <img src="https://github.com/danny-avila/LibreChat/assets/32828263/4c51dc25-31d3-4c51-8c2a-0cdfb5a25033" style={{ width: "75%", height: "75%" }} alt="Image for Light Theme" />
  </div>

  <div className="image-dark-theme">
    <img src="https://github.com/danny-avila/LibreChat/assets/32828263/3bc5371d-e51d-4e91-ac68-56db6e85bb2c" style={{ width: "75%", height: "75%" }} alt="Image for Dark Theme" />
  </div>
</div>

* General Settings:

\<OptionTable
options={\[
\['ALLOW\_EMAIL\_LOGIN', 'boolean', 'Enable or disable ONLY email login.','ALLOW\_EMAIL\_LOGIN=true'],
\['ALLOW\_REGISTRATION', 'boolean', 'Enable or disable Email registration of new users.','ALLOW\_REGISTRATION=true'],
\['ALLOW\_SOCIAL\_LOGIN', 'boolean', 'Allow users to connect to LibreChat with various social networks.','ALLOW\_SOCIAL\_LOGIN=false'],
\['ALLOW\_SOCIAL\_REGISTRATION', 'boolean', 'Enable or disable registration of new users using various social networks.','ALLOW\_SOCIAL\_REGISTRATION=false'],
\['ALLOW\_PASSWORD\_RESET', 'boolean', 'Enable or disable the ability for users to reset their password by themselves','ALLOW\_PASSWORD\_RESET=false'],
\['ALLOW\_ACCOUNT\_DELETION', 'boolean', 'Enable or disable the ability for users to delete their account by themselves. Enabled by default if omitted/commented out','ALLOW\_ACCOUNT\_DELETION=true'],
\['ALLOW\_UNVERIFIED\_EMAIL\_LOGIN', 'boolean', 'Set to true to allow users to log in without verifying their email address. If set to false, users will be required to verify their email before logging in.', 'ALLOW\_UNVERIFIED\_EMAIL\_LOGIN=true'],
]}
/>

> **Quick Tip:** Even with registration disabled, add users directly to the database using `npm run create-user`.
> **Quick Tip:** With registration disabled, you can delete a user with `npm run delete-user email@domain.com`.

* Session and Refresh Token Settings:

\<OptionTable
options={\[
\['SESSION\_EXPIRY', 'integer (milliseconds)', 'Session expiry time.','SESSION\_EXPIRY=1000 \* 60 \* 15'],
\['REFRESH\_TOKEN\_EXPIRY', 'integer (milliseconds)', 'Refresh token expiry time.','REFRESH\_TOKEN\_EXPIRY=(1000 \* 60 \* 60 \* 24) \* 7'],
]}
/>

* For more information: **Refresh Token**

* JWT Settings:

You should use new secure values. The examples given are 32-byte keys (64 characters in hex).
Use this replit to generate some quickly: **JWT Keys**

\<OptionTable
options={\[
\['JWT\_SECRET', 'string (hex)', 'JWT secret key.','JWT\_SECRET=16f8c0ef4a5d391b26034086c628469d3f9f497f08163ab9b40137092f2909ef'],
\['JWT\_REFRESH\_SECRET', 'string (hex)', 'JWT refresh secret key.','JWT\_REFRESH\_SECRET=eaa5191f2914e30b9387fd84e254e4ba6fc51b4654968a9b0803b456a54b8418'],
]}
/>

### Social Logins

For more details: OAuth2-OIDC

#### Discord Authentication

For more information: **Discord**

\<OptionTable
options={\[
\['DISCORD\_CLIENT\_ID', 'string', 'Your Discord client ID.','DISCORD\_CLIENT\_ID='],
\['DISCORD\_CLIENT\_SECRET', 'string', 'Your Discord client secret.','DISCORD\_CLIENT\_SECRET='],
\['DISCORD\_CALLBACK\_URL', 'string', 'The callback URL for Discord authentication.','DISCORD\_CALLBACK\_URL=/oauth/discord/callback'],
]}
/>

#### Facebook Authentication

For more information: **Facebook Authentication**

\<OptionTable
options={\[
\['FACEBOOK\_CLIENT\_ID', 'string', 'Your Facebook client ID.','FACEBOOK\_CLIENT\_ID='],
\['FACEBOOK\_CLIENT\_SECRET', 'string', 'Your Facebook client secret.','FACEBOOK\_CLIENT\_SECRET='],
\['FACEBOOK\_CALLBACK\_URL', 'string', 'The callback URL for Facebook authentication.','FACEBOOK\_CALLBACK\_URL=/oauth/facebook/callback'],
]}
/>

#### GitHub Authentication

For more information: **GitHub Authentication**

\<OptionTable
options={\[
\['GITHUB\_CLIENT\_ID', 'string', 'Your GitHub client ID.','GITHUB\_CLIENT\_ID='],
\['GITHUB\_CLIENT\_SECRET', 'string', 'Your GitHub client secret.','GITHUB\_CLIENT\_SECRET='],
\['GITHUB\_CALLBACK\_URL', 'string', 'The callback URL for GitHub authentication.','GITHUB\_CALLBACK\_URL=/oauth/github/callback'],
]}
/>

#### Google Authentication

For more information: **Google Authentication**

\<OptionTable
options={\[
\['GOOGLE\_CLIENT\_ID', 'string', 'Your Google client ID.','GOOGLE\_CLIENT\_ID='],
\['GOOGLE\_CLIENT\_SECRET', 'string', 'Your Google client secret.','GOOGLE\_CLIENT\_SECRET='],
\['GOOGLE\_CALLBACK\_URL', 'string', 'The callback URL for Google authentication.','GOOGLE\_CALLBACK\_URL=/oauth/google/callback'],
]}
/>

#### OpenID Connect

For more information:

* AWS Cognito
* Azure Entra/AD
* Keycloak

\<OptionTable
options={\[
\['OPENID\_CLIENT\_ID', 'string', 'Your OpenID client ID.','OPENID\_CLIENT\_ID='],
\['OPENID\_CLIENT\_SECRET', 'string', 'Your OpenID client secret.','OPENID\_CLIENT\_SECRET='],
\['OPENID\_ISSUER', 'string', 'The OpenID issuer URL.','OPENID\_ISSUER='],
\['OPENID\_SESSION\_SECRET', 'string', 'The secret for OpenID session storage.','OPENID\_SESSION\_SECRET='],
\['OPENID\_SCOPE', 'string', 'The OpenID scope.', 'OPENID\_SCOPE="openid profile email"'],
\['OPENID\_CALLBACK\_URL', 'string', 'The callback URL for OpenID authentication.','OPENID\_CALLBACK\_URL=/oauth/openid/callback'],
\['OPENID\_REQUIRED\_ROLE', 'string', 'The required role for validation.','OPENID\_REQUIRED\_ROLE='],
\['OPENID\_REQUIRED\_ROLE\_TOKEN\_KIND', 'string', 'The token kind for required role validation.','OPENID\_REQUIRED\_ROLE\_TOKEN\_KIND='],
\['OPENID\_REQUIRED\_ROLE\_PARAMETER\_PATH', 'string', 'The parameter path for required role validation.','OPENID\_REQUIRED\_ROLE\_PARAMETER\_PATH='],
\['OPENID\_BUTTON\_LABEL', 'string', 'The label for the OpenID login button.','OPENID\_BUTTON\_LABEL='],
\['OPENID\_IMAGE\_URL', 'string', 'The URL of the OpenID login button image.','OPENID\_IMAGE\_URL='],
]}
/>

#### LDAP/AD Authentication

For more information: **LDAP/AD Authentication**

\<OptionTable
options={\[
\['LDAP\_URL', 'string', 'LDAP server URL.', 'LDAP\_URL=ldap://localhost:389'],
\['LDAP\_BIND\_DN', 'string', 'Bind DN', 'LDAP\_BIND\_DN=cn=root'],
\['LDAP\_BIND\_CREDENTIALS', 'string', 'Password for bindDN', 'LDAP\_BIND\_CREDENTIALS=password'],
\[
'LDAP\_USER\_SEARCH\_BASE',
'string',
'LDAP user search base',
'LDAP\_USER\_SEARCH\_BASE=o=users,o=example.com',
],
\['LDAP\_SEARCH\_FILTER', 'string', 'LDAP search filter', 'LDAP\_SEARCH\_FILTER=mail={{username}}'],
\[
'LDAP\_CA\_CERT\_PATH',
'string',
'CA certificate path.',
'LDAP\_CA\_CERT\_PATH=/path/to/root\_ca\_cert.crt',
],
\[
'LDAP\_TLS\_REJECT\_UNAUTHORIZED',
'string',
'LDAP TLS verification',
'LDAP\_TLS\_REJECT\_UNAUTHORIZED=true',
],
]}
/>

### Password Reset

Email is used for account verification and password reset. See: **Email setup**

**Important Note**: All of the service or host, username, and password, and the From address must be set for email to work.

> **Warning**: If using `EMAIL_SERVICE`, **do NOT** set the extended connection parameters:
> HOST, PORT, ENCRYPTION, ENCRYPTION\_HOSTNAME, ALLOW\_SELFSIGNED.
> Failing to set valid values here will result in LibreChat using the unsecured password reset!

See: **nodemailer well-known-services**

\<OptionTable
options={\[
\['EMAIL\_SERVICE', 'string', 'Email service (e.g., Gmail, Outlook).','EMAIL\_SERVICE='],
\['EMAIL\_HOST', 'string', 'Mail server host.','EMAIL\_HOST='],
\['EMAIL\_PORT', 'number', 'Mail server port.','EMAIL\_PORT=25'],
\['EMAIL\_ENCRYPTION', 'string', 'Encryption method (starttls, tls, etc.).','EMAIL\_ENCRYPTION='],
\['EMAIL\_ENCRYPTION\_HOSTNAME', 'string', 'Hostname for encryption.','EMAIL\_ENCRYPTION\_HOSTNAME='],
\['EMAIL\_ALLOW\_SELFSIGNED', 'boolean', 'Allow self-signed certificates.','EMAIL\_ALLOW\_SELFSIGNED='],
\['EMAIL\_USERNAME', 'string', 'Username for authentication.','EMAIL\_USERNAME='],
\['EMAIL\_PASSWORD', 'string', 'Password for authentication.','EMAIL\_PASSWORD='],
\['EMAIL\_FROM\_NAME', 'string', 'From name.','EMAIL\_FROM\_NAME='],
\['EMAIL\_FROM', 'string', 'From email address. Required.','EMAIL\_FROM=noreply@librechat.ai'],
]}
/>

### Firebase CDN

See: **Firebase CDN Configuration**

<Callout type="warning" title="Important">
- If you are using Firebase as your file storage strategy, make sure to set the `file_strategy` option to `firebase` in your `librechat.yaml` configuration file. - For more information on configuring the `librechat.yaml` file, please refer to the YAML Configuration Guide: [Custom Endpoints & Configuration](/docs/configuration/librechat_yaml)
</Callout>

\<OptionTable
options={\[
\['FIREBASE\_API\_KEY', 'string', 'The API key for your Firebase project.', 'FIREBASE\_API\_KEY='],
\['FIREBASE\_AUTH\_DOMAIN', 'string', 'The Firebase Auth domain for your project.', 'FIREBASE\_AUTH\_DOMAIN='],
\['FIREBASE\_PROJECT\_ID', 'string', 'The ID of your Firebase project.', 'FIREBASE\_PROJECT\_ID='],
\['FIREBASE\_STORAGE\_BUCKET', 'string', 'The Firebase Storage bucket for your project.', 'FIREBASE\_STORAGE\_BUCKET='],
\['FIREBASE\_MESSAGING\_SENDER\_ID', 'string', 'The Firebase Cloud Messaging sender ID.', 'FIREBASE\_MESSAGING\_SENDER\_ID='],
\['FIREBASE\_APP\_ID', 'string', 'The Firebase App ID for your project.', 'FIREBASE\_APP\_ID='],
]}
/>

### UI

#### Help and FAQ Button

\<OptionTable
options={\[
\['HELP\_AND\_FAQ\_URL', 'string', 'Help and FAQ URL. If empty or commented, the button is enabled.','HELP\_AND\_FAQ\_URL=https://librechat.ai'],
]}
/>

**Behaviour:**

Sets the Cache-Control headers for static files. These configurations only trigger when the `NODE_ENV` is set to `production`.

Properly setting cache headers is crucial for optimizing the performance and efficiency of your web application. By controlling how long browsers and CDNs store copies of your static files, you can significantly reduce server load, decrease page load times, and improve the overall user experience.

* Uncomment `STATIC_CACHE_MAX_AGE` to change the `max-age` for static files. By default this is set to 4 weeks.
* Uncomment `STATIC_CACHE_S_MAX_AGE` to change the `s-maxage` for static files. By default this is set to 1 week.
  * This is for the *shared cache*, which is used by CDNs and proxies.

#### App Title and Footer

\<OptionTable
options={\[
\['APP\_TITLE', 'string', 'App title.','APP\_TITLE=LibreChat'],
\['CUSTOM\_FOOTER', 'string', 'Custom footer.','# CUSTOM\_FOOTER="My custom footer"'],
]}
/>

**Behaviour:**

* Uncomment `CUSTOM_FOOTER` to add a custom footer.
* Uncomment and leave `CUSTOM_FOOTER` empty to remove the footer.
* You can now add one or more links in the CUSTOM\_FOOTER value using the following format: `[Anchor text](URL)`. Each link should be delineated with a pipe (`|`).

> **Markdown example:** `CUSTOM_FOOTER=[Link 1](http://example1.com) | [Link 2](http://example2.com)`

#### Birthday Hat

\<OptionTable
options={\[
\['SHOW\_BIRTHDAY\_ICON', 'boolean', 'Show the birthday hat icon.','# SHOW\_BIRTHDAY\_ICON=true'],
]}
/>

**Behaviour:**

* The birthday hat icon will show automatically on February 11th (LibreChat's birthday).
* Set `SHOW_BIRTHDAY_ICON` to `false` to disable the birthday hat.
* Set `SHOW_BIRTHDAY_ICON` to `true` to enable the birthday hat all the time.

### Analytics

#### Google Tag Manager

LibreChat supports Google Tag Manager for analytics. You will need a Google Tag Manager ID to enable it in LibreChat. Follow this guide to generate a Google Tag Manager ID and configure Google Analytics. Then set the `ANALYTICS_GTM_ID` environment variable to your Google Tag Manager ID.

**Note:** If `ANALYTICS_GTM_ID` is not set, Google Tag Manager will not be enabled. If it is set incorrectly, you will see failing requests to `gtm.js`

\<OptionTable
options={\[
\['ANALYTICS\_GTM\_ID', 'string', 'Google Tag Manager ID.','ANALYTICS\_GTM\_ID='],
]}
/>

### Other

#### Redis

**Note:** Redis support is experimental, and you may encounter some problems when using it.

**Important:** If using Redis, you should flush the cache after changing any LibreChat settings.

\<OptionTable
options={\[
\['REDIS\_URI', 'string', 'Redis URI.','# REDIS\_URI='],
\['USE\_REDIS', 'boolean', 'Use Redis.','# USE\_REDIS='],
]}
/>
