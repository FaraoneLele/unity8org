/*
 * Copyright (C) 2016 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtTest 1.0
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3
import Unity.Application 0.1
import Unity.Test 0.1
import Utils 0.1
import QMenuModel 0.1

import ".."
import "../../../qml/Stage"

Item {
    id: root
    width:  units.gu(70)
    height:  units.gu(50)

    Component.onCompleted: {
        QuickUtils.keyboardAttached = true;
        theme.name = "Ubuntu.Components.Themes.SuruDark"
    }

    Binding {
        target: MouseTouchAdaptor
        property: "enabled"
        value: false
    }

    property QtObject application: QtObject {
        property string name: "webbrowser"
    }

    ApplicationMenuDataLoader { id: menuData }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: units.gu(1)
        }
        height: units.gu(20)
        border.width: 1
        border.color: "black"

        TextArea {
            id: log
            anchors.fill: parent
            readOnly: true
        }
    }

    WindowDecoration {
        id: decoration
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: units.gu(1)
        target: root
        title: "TestTitle - Doing something"
        active: true
        height: units.gu(3)
        menu: menuBackend
        UnityMenuModel {
            id: menuBackend
            modelData: menuData.generateTestData(5, 3, 3, "menu")
            onActivated: log.text = "Activated " + action + "\n" + log.text
        }

        onCloseClicked: log.text = "Close\n" + log.text
        onMinimizeClicked: log.text = "Minimize\n" + log.text
        onMaximizeClicked: log.text = "Maximize\n" + log.text
    }

    SignalSpy {
        id: signalSpy
        target: decoration
    }

    UnityTestCase {
        id: testCase
        name: "WindowDecoration"
        when: windowShown

        function init() {
            decoration.menu = menuBackend;
            signalSpy.clear();
        }

        function test_windowControlButtons_data() {
            return [ { tag: "close", controlName: "closeWindowButton", signal: "close"},
                    { tag: "minimize", controlName: "minimizeWindowButton", signal: "minimize"},
                    { tag: "maximize", controlName: "maximizeWindowButton", signal: "maximize"}];
        }

        function test_windowControlButtons(data) {
            signalSpy.signalName = data.signal;
            var controlButton = findChild(decoration, data.controlName);
            verify(controlButton !== null);

            mouseClick(controlButton, controlButton.width/2, controlButton.height/2);
            compare(signalSpy.count, 1);
        }

        function test_titleRemainsWhenHoveringOnTitleBarWithNoMenu() {
            decoration.menu = undefined;

            var menuLoader = findChild(decoration, "menuBarLoader");
            verify(menuLoader);
            mouseMove(menuLoader, menuLoader.width/2, menuLoader.height/2);
            wait(200);

            var titleLabel = findChild(decoration, "windowDecorationTitle");
            verify(menuLoader);

            compare(menuLoader.opacity, 0, "Menu should not show when present")
            compare(titleLabel.opacity, 1, "Title should always show when app menu not present")
        }

        function test_menuShowsWhenHoveringOnTitleBar() {
            var menuLoader = findChild(decoration, "menuBarLoader");
            verify(menuLoader);
            mouseMove(menuLoader, menuLoader.width/2, menuLoader.height/2)

            var titleLabel = findChild(decoration, "windowDecorationTitle");
            verify(menuLoader);

            tryCompare(menuLoader, "opacity", 1);
            tryCompare(titleLabel, "opacity", 0);

            mouseMove(menuLoader, menuLoader.width/2, menuLoader.height * 2);

            tryCompare(menuLoader, "opacity", 0);
            tryCompare(titleLabel, "opacity", 1);
        }

        function test_showMenuBarWithShortcutsOnLongAltPress() {
            var menuLoader = findChild(decoration, "menuBarLoader");
            verify(menuLoader);

            var titleLabel = findChild(decoration, "windowDecorationTitle");
            verify(menuLoader);

            var menuBar = findChild(decoration, "menuBar");
            verify(menuBar);
            verify(menuBar.enableMnemonic === false, "Menubar should not show shortcuts")

            keyPress(Qt.Key_Alt, Qt.NoModifier);
            tryCompare(menuLoader, "opacity", 1);
            tryCompare(titleLabel, "opacity", 0);
            compare(menuBar.enableMnemonic, true, "Menubar should show shortcuts when long alt pressed");

            keyRelease(Qt.Key_Alt, Qt.NoModifier);
            tryCompare(menuLoader, "opacity", 0);
            tryCompare(titleLabel, "opacity", 1);
            compare(menuBar.enableMnemonic, false, "Menubar should not show shortcuts after long alt pressed");
        }
    }
}
