import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	visible: MprisService.playing

	IconText {
		glyph: "\uf001"
		text: {
			if (!MprisService.title)
				return "";
			const artistPart = MprisService.artist ? " - " + MprisService.artist : "";
			return MprisService.title + artistPart;
		}
		glyphColor: MprisService.playing ? Theme.accent : Theme.fg
		textColor: Theme.fg
		maxTextWidth: 180
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}