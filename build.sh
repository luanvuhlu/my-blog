#!/bin/bash

lektor clean --yes 

lektor build

mkdir build && cp -r $(lektor project-info --output-path)/* build/ 

firebase deploy
