const vscode = require('vscode');

function activate(context) {
    async function openWith(uri, command) {
        if (uri) {
            await vscode.commands.executeCommand('vscode.open', uri);
        }
        await vscode.commands.executeCommand(command);
    }

    context.subscriptions.push(
        vscode.commands.registerCommand('adoc-preview-menu.openPreview',
            (uri) => openWith(uri, 'asciidoc.showPreview')),
        vscode.commands.registerCommand('adoc-preview-menu.openPreviewToSide',
            (uri) => openWith(uri, 'asciidoc.showPreviewToSide'))
    );
}

function deactivate() {}

module.exports = { activate, deactivate };
