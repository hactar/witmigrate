**Warning:** While this tool works, its more like a hack for personal use than an official tool. It may or my not work for you out of the box, but should provide you with a starter for your own solution.

## Witmigrate Tool
This is a tool, written in swift, to migrate legacy wit.ai non-story models into the new story based system. The download feature of this tool is incomplete (I ended up downloading all old intents and entities with a simple curl script), but once you have all intents and entities downloaded from the wit.ai api, you can use this tool to generate a fake backup file, which you can import into wit during app creation, to have it include your old intents, entities and trained expressions.

## Idea
Even if you don't use this tool, the procedure my be of interest, you could reimplement it in your favorite language. The idea is to:

1. Download the old intents and entities from the wit api
2. Create a new action named "wave_legacy" that will be called whenever wit wants you to run one of your old intents
3. Create 1 story per intent/role/entity combination and assign the "wave_legacy" action to it
4. Package all of this with your old expressions, intents and entities, creating an importable zip file for a new story based wit.ai app.

## Usage
For more information on how to download the required json file from the legacy API, visit: https://wit.ai/docs/http/20170307
1. Create a folder named Input
1. Download your intents list from GET https://api.wit.ai/intents and store it under Input/Intents/intents.json
1. Download the individual intents GET https://api.wit.ai/intents/$INTENT_ID and store them under Input/Intents/INTENTNAME.json
1. Download the individual entities from https://wit.ai/docs/http/20170307#get--entities-:entity-id-link and store them under Input/Entities/ENTITYNAME.json
1. Copy over the acions.json and operations_stub into the Input folder.
1. Install the Swift package manager dependencies via `swift package generate-xcodepro`
1. Compile witmigrate
1. Run `witmigrate generate PATHTOINPUTFOLDER`
1. Run `zip outputFolder.zip outputFolder/app.json outputFolder/entities/*.json outputFolder/actions.json outputFolder/stories.json outputFolder/expressions.json` to create the zip folder
1. Create a new wit.ai app and select the zip file for import

## Why Swift 3?
This tool was meant as a private tool to migrate one of my apps, and as I'm an iOS developer this was a natural choice. If you don't have a swift environment you could try setting up via docker: https://github.com/swiftdocker/docker-swift

## Known Issues
* For a list of wit import and export issues that also affect this tool, visit: https://github.com/wit-ai/wit/issues/513