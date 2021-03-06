/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2014 Osmo Salomaa
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

import "js/util.js" as Util

Page {
    id: page
    allowedOrientations: app.defaultAllowedOrientations

    property bool   loading: false
    property string populatedQuery: ""
    property var    results: {}
    property string title: ""

    SilicaGridView {
        id: view
        anchors.fill: parent
        cellHeight: Theme.itemSizeMedium
        cellWidth: {
            // Use a dynamic column count based on available screen width.
            var width = page.isPortrait ? Screen.width : Screen.height;
            return width / Math.floor(width / (Theme.pixelRatio * 400));
        }

        delegate: StopListItem {
            id: listItem
            width: view.cellWidth
            Component.onCompleted: {
                view.cellHeight = Math.max(view.cellHeight, listItem.contentHeight);
                listItem.contentHeight = view.cellHeight;
            }
            onClicked: app.pageStack.push("StopPage.qml", {"props": model});
        }

        header: PageHeader {
            title: page.title
        }

        model: ListModel {}

        VerticalScrollDecorator {}

    }

    BusyModal {
        id: busy
        running: page.loading
    }

    onStatusChanged: {
        if (page.populatedQuery === app.searchQuery) {
            return;
        } else if (page.status === PageStatus.Activating) {
            view.model.clear();
            page.loading = true;
            page.title = "";
            busy.text = app.tr("Searching")
        } else if (page.status === PageStatus.Active) {
            page.populate(app.searchQuery);
        }
    }

    function populate(query) {
        // Load stops from the Python backend.
        py.call_sync("pan.app.history.add", [query]);
        view.model.clear();
        var x = gps.position.coordinate.longitude || 0;
        var y = gps.position.coordinate.latitude || 0;
        py.call("pan.app.provider.find_stops", [query, x, y], function(results) {
            if (results && results.error && results.message) {
                page.title = "";
                busy.error = results.message;
            } else if (results && results.length > 0) {
                page.results = results;
                page.title = app.tr("%1 Stops", results.length);
                Util.appendAll(view.model, results);
            } else {
                page.title = "";
                busy.error = app.tr("No stops found");
            }
            page.loading = false;
            page.populatedQuery = query;
        });
    }

}
