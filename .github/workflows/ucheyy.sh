name: Getting started

on:
  push:
    branches: [ main, ]
  pull_request:
    branches: [ main ]

jobs:
  build:

   runs-on: ubuntu-latest

   steps:
     - uses: actions/checkout@v2

     - name: Run a one-line script
       run: sh ./look.sh

