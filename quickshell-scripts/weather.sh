#!/bin/bash

# Localidade configurável: defina CADROCBAR_WEATHER_LOCATION no ambiente
# (ex.: export CADROCBAR_WEATHER_LOCATION="Lisbon") ou crie o arquivo
# ~/.config/cadrocbar/weather.location contendo a cidade.
# Vazio = usa a localização automática do wttr.in (por IP).
LOCATION="${CADROCBAR_WEATHER_LOCATION:-}"
if [ -z "$LOCATION" ] && [ -r "$HOME/.config/cadrocbar/weather.location" ]; then
	LOCATION=$(head -n1 "$HOME/.config/cadrocbar/weather.location" | tr -d '\r')
fi

URL="https://wttr.in/${LOCATION}"

# %c: condição (ex: ☀️), %t: temperatura, %w: vento, %h: umidade
WEATHER=$(curl -s --max-time 5 "${URL}?format=%c+%t+%w+%h&m")

# Separa os campos e emite JSON para a barra
# Exemplo de saída: "☀️ +17°C ↙14km/h 72%"
if [ -n "$WEATHER" ]; then
	cond=$(echo "$WEATHER" | awk '{print $1}')
	temp=$(echo "$WEATHER" | awk '{print $2}')
	wind=$(echo "$WEATHER" | awk '{print $3}')
	hum=$(echo "$WEATHER" | awk '{print $4}')
	# Converte a condição em um glyph da Nerd Font (como caractere unicode real)
	case "$cond" in
		*☀*|*Sunny*|*Clear*) glyph=$(printf '\uf185') ;;
		*⛅*|*Partly*|*partly*) glyph=$(printf '\uf6c4') ;;
		*☁*|*Cloudy*|*Overcast*) glyph=$(printf '\uf0c2') ;;
		*🌧*|*Rain*|*rain*) glyph=$(printf '\uf043') ;;
		*⛈*|*Thunder*|*storm*) glyph=$(printf '\uf42a') ;;
		*🌨*|*Snow*|*snow*) glyph=$(printf '\uf2dc') ;;
		*🌫*|*Fog*|*fog*|*Mist*) glyph=$(printf '\uf0b6') ;;
		*) glyph=$(printf '\uf185') ;;
	esac
	printf '{"cond":"%s","glyph":"%s","temp":"%s","wind":"%s","hum":"%s"}\n' \
		"$cond" "$glyph" "$temp" "$wind" "$hum"
fi