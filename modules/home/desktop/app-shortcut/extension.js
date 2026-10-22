import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import * as AppDisplay from 'resource:///org/gnome/shell/ui/appDisplay.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const MENU_LABEL = 'Crear acceso directo en el escritorio';
const MENU_ICON = 'document-new-symbolic';

export default class DesktopShortcutExtension extends Extension {
    enable() {
        this._menus = new Set();
        this._originalPopupMenu = AppDisplay.AppIcon.prototype.popupMenu;

        const extension = this;
        AppDisplay.AppIcon.prototype.popupMenu = function () {
            const result = extension._originalPopupMenu.call(this);
            extension._augmentMenu(this);
            return result;
        };
    }

    disable() {
        if (this._originalPopupMenu) {
            AppDisplay.AppIcon.prototype.popupMenu = this._originalPopupMenu;
            this._originalPopupMenu = null;
        }

        for (const menu of this._menus) {
            const item = menu._desktopShortcutItem;
            if (item) {
                try {
                    item.destroy();
                } catch (_error) {
                    // El menú pudo haber sido destruido con el icono.
                }
                delete menu._desktopShortcutItem;
            }
        }
        this._menus.clear();
    }

    _augmentMenu(icon) {
        const menu = icon._menu;
        if (!menu || menu._desktopShortcutItem)
            return;

        const item = menu.addAction(MENU_LABEL, () => {
            this._createShortcut(icon.app);
        }, MENU_ICON);
        menu._desktopShortcutItem = item;
        this._menus.add(menu);

        const details = menu._detailsItem;
        if (details) {
            const items = menu._getMenuItems();
            const index = items.indexOf(details);
            if (index >= 0)
                menu.moveMenuItem(item, index + 1);
        }
    }

    _desktopDirectory() {
        const directory = GLib.get_user_special_dir(
            GLib.UserDirectory.DIRECTORY_DESKTOP,
        );
        if (directory)
            return directory;

        return GLib.build_filenamev([GLib.get_home_dir(), 'Escritorio']);
    }

    _createShortcut(app) {
        const appInfo = app?.get_app_info?.();
        if (!appInfo) {
            Main.notify('Acceso directo',
                'No se pudo obtener la información de la aplicación.');
            return;
        }

        const desktopDirectory = this._desktopDirectory();
        const status = GLib.mkdir_with_parents(desktopDirectory, 0o755);
        if (status !== 0 &&
            !GLib.file_test(desktopDirectory, GLib.FileTest.IS_DIR)) {
            Main.notify('Acceso directo',
                `No se pudo crear el directorio ${desktopDirectory}.`);
            return;
        }

        const sourcePath = appInfo.get_filename?.() ?? null;
        const appId = app.get_id();
        const sourceName = sourcePath
            ? GLib.path_get_basename(sourcePath)
            : appId.endsWith('.desktop')
                ? appId
                : `${appId}.desktop`;
        const fileName = sourceName.endsWith('.desktop')
            ? sourceName
            : `${sourceName}.desktop`;
        const destinationPath = GLib.build_filenamev([desktopDirectory, fileName]);

        if (GLib.file_test(destinationPath, GLib.FileTest.EXISTS)) {
            Main.notify('Acceso directo', `Ya existe: ${fileName}`);
            return;
        }

        try {
            if (sourcePath) {
                const source = Gio.File.new_for_path(sourcePath);
                const destination = Gio.File.new_for_path(destinationPath);
                if (!source.copy(destination, Gio.FileCopyFlags.NONE, null, null))
                    throw new Error('la copia del archivo .desktop falló');
            } else {
                const contents = [
                    '[Desktop Entry]',
                    'Type=Application',
                    `Name=${app.get_name()}`,
                    `Exec=${appInfo.get_string('Exec') ?? `gtk-launch ${appId}`}`,
                    `Icon=${appInfo.get_string('Icon') ?? ''}`,
                    'Terminal=false',
                    '',
                ].join('\n');
                if (!GLib.file_set_contents(destinationPath, contents))
                    throw new Error('no se pudo escribir el archivo .desktop');
            }

            this._markExecutable(destinationPath);
            this._markTrusted(destinationPath);
            Main.notify('Acceso directo',
                `Creado en el escritorio: ${fileName}`);
        } catch (error) {
            Main.notify('Acceso directo',
                `Error al crear el acceso directo: ${error.message}`);
        }
    }

    _markExecutable(path) {
        const file = Gio.File.new_for_path(path);
        const info = new Gio.FileInfo();
        info.set_attribute_uint32(Gio.FILE_ATTRIBUTE_UNIX_MODE, 0o755);
        try {
            file.set_attributes_from_info(
                info,
                Gio.FileQueryInfoFlags.NONE,
                null,
            );
        } catch (error) {
            console.warn(`No se pudo marcar como ejecutable ${path}: ${error.message}`);
        }
    }

    _markTrusted(path) {
        const file = Gio.File.new_for_path(path);
        const info = new Gio.FileInfo();
        info.set_attribute_string('metadata::trusted', 'true');
        try {
            file.set_attributes_from_info(
                info,
                Gio.FileQueryInfoFlags.NONE,
                null,
            );
        } catch (error) {
            console.warn(`No se pudo marcar como confiable ${path}: ${error.message}`);
        }
    }
}
