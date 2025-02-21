/*
 * Vencord, a Discord client mod
 * Copyright (c) 2024 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { Logger } from "@utils/Logger";
import { PluginNative } from "@utils/types";

export const BooruLogger = new Logger("BooruHandler");

export function getNative(): PluginNative<typeof import("./native")> {
    return Object.values(VencordNative.pluginHelpers)
        .find(m => m.booruSearchPlugin) as PluginNative<typeof import("./native")>;
}
