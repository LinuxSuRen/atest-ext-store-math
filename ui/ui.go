package ui

import (
	_ "embed"
)

//go:embed dist/atest-ext-store-math.umd.js
var js string

//go:embed dist/atest-ext-store-math.css
var css string

func GetJS() string {
	return js
}

func GetCSS() string {
	return css
}
