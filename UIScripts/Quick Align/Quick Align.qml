import QtQuick 2.3
import QtQuick.Dialogs 1.1

import Thinkbox.Sequoia.Nodes 1.0

Item {
	id: toolBody
	Component.onCompleted: {
		var sel = NodeSelection.getSelectedSequoiaNodes();
		if (sel.length > 1) 
		{
			var pos = NodeControl.getNodePosition (sel[0]);
			var i = 1;
			for (i = 1; i < sel.length; i++)
			{
				NodeControl.setNodePosition (pos, sel[i] );
			}
		}
		else 
		{
			console.log("Please select at least two objects!")
		}
		Qt.quit()
	}
}


