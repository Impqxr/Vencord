/*
 * Vencord, a Discord client mod
 * Copyright (c) 2024 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { findOption } from "@api/Commands";
import { ApplicationCommandInputType, ApplicationCommandOptionType } from "@api/Commands/types";
import { definePluginSettings } from "@api/Settings";
import { sendMessage } from "@utils/discord";
import definePlugin, { OptionType } from "@utils/types";

const settings = definePluginSettings({
    debloat: {
        type: OptionType.BOOLEAN,
        default: false,
        description: "Debloat Google search(no AI, only links)",
        restartNeeded: false
    }
});

export default definePlugin({
    name: "LMGTFY",
    description: "Let Me Google That For You",
    authors: [{ name: "Impqxr", id: 458605907245400064n }],
    dependencies: ["CommandsAPI"],
    settings,
    commands: [
        {
            name: "lmgtfy",
            description: "Let Me Google That For You",
            inputType: ApplicationCommandInputType.BUILT_IN,
            options: [
                {
                    type: ApplicationCommandOptionType.STRING,
                    name: "query",
                    description: "Query",
                    required: true
                },
            ],
            execute: async (args, ctx) => {
                const query = findOption(args, "query", "MISSING");
                sendMessage(ctx.channel.id, { content: `https://google.com/search?q=${encodeURIComponent(query)}${settings.store.debloat ? "&udm=14" : ""}` });
            }
        }
    ]
});
