/*
 * Vencord, a Discord client mod
 * Copyright (c) 2024 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { ApplicationCommandOptionType, findOption, sendBotMessage } from "@api/Commands";
import { ApplicationCommandInputType } from "@api/Commands/types";
import { definePluginSettings } from "@api/Settings";
import { sendMessage } from "@utils/discord";
import definePlugin, { OptionType } from "@utils/types";

import { BooruLogger, getNative } from "./utils";

const Native = getNative();

const MAX_PAGE = 476;
const MAX_PAGE_POSTS = 42;


async function sendRequest(dataSearchParams: URLSearchParams, page: number) {
    dataSearchParams.set("pid", page.toString());
    if (settings.store.apikey)
        dataSearchParams.set("api_key", settings.store.apikey);
    if (settings.store.userid)
        dataSearchParams.set("user_id", settings.store.userid);

    const info = await Native.requestBooru("https://gelbooru.com/index.php?" + dataSearchParams);

    if (info.status === 0 && "@attributes" in info.content) {
        return { info: info.content, posts: info.content["@attributes"].count };
    } else {
        BooruLogger.error(info.error);
    }
    return { info: null, posts: null };
}

const settings = definePluginSettings({
    userid: {
        description: "User ID (Optional)",
        type: OptionType.STRING,
        default: "",
        restartNeeded: false
    },
    apikey: {
        description: "API Key (Optional)",
        type: OptionType.STRING,
        default: "",
        restartNeeded: false
    }
});

export default definePlugin({
    name: "Booru",
    description: "Use booru as a slash command. See https://gelbooru.com/index.php?page=wiki&s=&s=view&id=26263 to understand the logic of tags",
    authors: [{ name: "Impqxr", id: 458605907245400064n }],
    dependencies: ["CommandsAPI"],
    settings,
    commands: [
        {
            name: "booru",
            description: "Search images from Gelbooru",
            inputType: ApplicationCommandInputType.BUILT_IN,
            options: [
                {
                    type: ApplicationCommandOptionType.STRING,
                    name: "tags",
                    description: "Tags(space is a separator between tags)",
                    required: false
                },
                // TODO: implement
                // {
                //     type: ApplicationCommandOptionType.INTEGER,
                //     name: "count",
                //     description: "How many pictures? (from 1 to 5)",
                //     required: false,
                // }
            ],
            execute: async (args, ctx) => {
                try {
                    const tags = findOption(args, "tags", "");

                    BooruLogger.debug(`------- ${tags} -------`);
                    const dataSearchParams = new URLSearchParams({
                        page: "dapi",
                        s: "post",
                        q: "index",
                        json: "1",
                        limit: MAX_PAGE_POSTS.toString(),
                    });

                    if (tags) {
                        dataSearchParams.set("tags", tags);
                    }

                    const zero_info = await sendRequest(dataSearchParams, 0);

                    if (!zero_info.posts) {
                        return void sendBotMessage(ctx.channel.id, { content: "No results found." });
                    }

                    BooruLogger.debug(`Pages: ${zero_info.posts / MAX_PAGE_POSTS} <-> Posts count: ${zero_info.posts}`);
                    let page = Math.trunc(zero_info.posts / MAX_PAGE_POSTS);
                    page = Math.floor(Math.random() * Math.min(page, MAX_PAGE));
                    BooruLogger.debug(`Selected page: ${page}`);

                    const { info } = await sendRequest(dataSearchParams, page);
                    const random_post_number = Math.floor(Math.random() * info.post.length);
                    BooruLogger.debug(`Random Post Number: ${random_post_number} <-> Posts in the page: ${info.post.length}`);
                    const random_post = info.post[random_post_number];
                    BooruLogger.debug(`Tags of the post: ${random_post.tags}`);

                    const msg = await sendMessage(ctx.channel.id, { content: random_post.file_url });

                    BooruLogger.debug(`------- ${JSON.parse(msg.text).id} -------`);

                } catch (error) {
                    sendBotMessage(ctx.channel.id, {
                        content: `Something went wrong: \`${error}\``,
                    });
                }
            }
        }
    ]
});
