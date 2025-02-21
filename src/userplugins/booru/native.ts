/*
 * Vencord, a Discord client mod
 * Copyright (c) 2024 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { IpcMainInvokeEvent } from "electron";

export function booruSearchPlugin() { }

export async function requestBooru(_event: IpcMainInvokeEvent, url: string) {
    // GelBooru doesn't have necessary headers
    return await fetch(url)
        .then(async result => { return { status: 0, content: await result.json(), error: "" }; })
        .catch(error => { return { status: 1, content: "", error: error }; });
}
