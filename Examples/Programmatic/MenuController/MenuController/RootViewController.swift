/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import Material

class RootViewController: UIViewController {
    /// A reference to the addButton.
    internal var addButton: FabButton!
    
    /// A reference to the audioLibraryMenuItem.
    internal var audioLibraryMenuItem: MenuItem!
    
    /// A reference to the reminderMenuItem.
    internal var reminderMenuItem: MenuItem!
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.grey.lighten1
        
        prepareAddButton()
        prepareAudioLibraryButton()
        prepareBellButton()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        prepareMenuController()
    }
    
    /// Handle the menu toggle event.
    internal func handleToggleMenu(button: Button) {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        if mc.menu.isOpened {
            mc.closeMenu { (view) in
                (view as? MenuItem)?.hideTitleLabel()
            }
        } else {
            mc.openMenu { (view) in
                (view as? MenuItem)?.showTitleLabel()
            }
        }
    }
    
    /// Prepares the addButton.
    private func prepareAddButton() {
        addButton = FabButton(image: Icon.cm.add, tintColor: Color.white)
        addButton.backgroundColor = Color.blue.base
        addButton.addTarget(self, action: #selector(handleToggleMenu), for: .touchUpInside)
    }
    
    /// Prepares the audioLibraryButton.
    private func prepareAudioLibraryButton() {
        audioLibraryMenuItem = MenuItem()
        audioLibraryMenuItem.button.image = Icon.cm.audioLibrary
        audioLibraryMenuItem.button.backgroundColor = Color.blue.base
        audioLibraryMenuItem.title = "Audio Library"
    }
    
    /// Prepares the bellButton.
    private func prepareBellButton() {
        reminderMenuItem = MenuItem()
        reminderMenuItem.button.image = Icon.cm.bell
        reminderMenuItem.button.backgroundColor = Color.blue.base
        reminderMenuItem.title = "Reminders"
    }
    
    /// Prepares the menuController.
    private func prepareMenuController() {
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        mc.menu.delegate = self
        mc.menu.views = [addButton, audioLibraryMenuItem, reminderMenuItem]
    }
}

/// MenuDelegate.
extension RootViewController: MenuDelegate {
    func menu(menu: Menu, tappedAt point: CGPoint, isOutside: Bool) {
        guard isOutside else {
            return
        }
        
        guard let mc = menuController as? AppMenuController else {
            return
        }
        
        mc.closeMenu { (view) in
            (view as? MenuItem)?.hideTitleLabel()
        }
    }
}