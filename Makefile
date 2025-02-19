SHELL := /bin/sh
.PHONY: gc macv macv-json libv libv-chs libv-cht fcitx5-chs fcitx5-cht install install-vchewing _remoteinstall-vchewing clean BuildDir format lint gitcfg prepare-macos prepare-linux-amd64 install-linux-chewing-amd64-chs install-linux-chewing-amd64-cht deploy-swift-env-linux

deploy-swift-env-linux:
	sudo apt install -y curl
	curl -s https://archive.swiftlang.xyz/install.sh | sudo bash
	sudo apt install swiftlang

install-linux-chewing-amd64-chs: prepare-linux-amd64 libv-chs
	@sudo cp ./Build/Release/LibChewing-CHS/dictionary.dat /usr/share/libchewing/
	@sudo cp ./Build/Release/LibChewing-CHS/index_tree.dat /usr/share/libchewing/
	@echo "\033[0;32m//$$(tput bold) 簡體中文威注音詞庫已部署至當前系統 /usr/share/libchewing 內，請手動重新啟動您在使用的主輸入法框架。$$(tput sgr0)\033[0m"

install-linux-chewing-amd64-cht: prepare-linux-amd64 libv-cht
	@sudo cp ./Build/Release/LibChewing-CHT/dictionary.dat /usr/share/libchewing/
	@sudo cp ./Build/Release/LibChewing-CHT/index_tree.dat /usr/share/libchewing/
	@echo "\033[0;32m//$$(tput bold) 繁體中文威注音詞庫已部署至當前系統 /usr/share/libchewing 內，請手動重新啟動您在使用的主輸入法框架。$$(tput sgr0)\033[0m"

prepare-macos:
	@echo "\033[0;32m//$$(tput bold) 已經準備設定 macOS 專用酷音編譯器……$$(tput sgr0)\033[0m"
	@cp ./bin/libchewing-database-initializer/init_database_macos_universal ./bin/libchewing-database-initializer/init_database

prepare-linux-amd64:
	@echo "\033[0;32m//$$(tput bold) 已經準備設定 Linux amd64 專用酷音編譯器……$$(tput sgr0)\033[0m"
	@cp ./bin/libchewing-database-initializer/init_database_linux_amd64 ./bin/libchewing-database-initializer/init_database

format:
	@swiftformat --swiftversion 5.5 --indent 2 ./

lint:
	@git ls-files --exclude-standard | grep -E '\.swift$$' | swiftlint --fix --autocorrect

clean:
	@rm -rf ./Build
	@rm -rf tsi-cht.src tsi-chs.src data-cht.txt data-chs.txt data-*.plist data-*.json phone.cin phone.cin-CNS11643-complete.patch
	
install: install-vchewing clean

BuildDir:
	@mkdir -p ./Build

fcitx5-chs: macv
	@echo "\033[0;32m//$$(tput bold) Linux: 正在生成 FCITX5 版小麥注音專用的簡體中文威注音語料檔案……$$(tput sgr0)\033[0m"
	@> ./mcbopomofo-data.txt
	@echo "# format org.openvanilla.mcbopomofo.sorted" >> ./mcbopomofo-data.txt
	@env LC_COLLATE=C.UTF-8 cat ./data-chs.txt >> ./mcbopomofo-data.txt
	
fcitx5-cht: macv
	@echo "\033[0;32m//$$(tput bold) Linux: 正在生成 FCITX5 版小麥注音專用的繁體中文威注音語料檔案……$$(tput sgr0)\033[0m"
	@> ./mcbopomofo-data.txt
	@echo "# format org.openvanilla.mcbopomofo.sorted" >> ./mcbopomofo-data.txt
	@env LC_COLLATE=C.UTF-8 cat ./data-cht.txt >> ./mcbopomofo-data.txt

fcitx5-install:
	@cp ./mcbopomofo-data.txt /usr/share/fcitx5/data/

macv:
	@mkdir -p ./Build/Release/
	@swift ./bin/cook_mac.swift
	@sqlite3 ./Build/Release/vChewingFactoryDatabase.sqlite < ./Build/Release/vChewingFactoryDatabase.sql

macv-json:
	@mkdir -p ./Build/Release/
	@swift ./bin/cook_mac.swift --json

libv:
	swift ./bin/cook_libchewing.swift chs
	swift ./bin/cook_libchewing.swift cht

libv-chs:
	@mkdir -p ./Build/Release/LibChewing-CHS/
	@mkdir -p ./Build/Intermediate/LibChewing-CHS/
	@swift ./bin/cook_libchewing.swift chs
	@diff -u "./Build/phone-chs.cin" "./Build/phone-chs-ex.cin" --label phone.cin --label phone-CNS11643-complete.cin > "./Build/Intermediate/LibChewing-CHS/phone.cin-CNS11643-complete.patch" || true
	@./bin/libchewing-database-initializer/init_database ./Build/phone-chs.cin ./Build/tsi-chs.src
	@mv ./Build/phone-chs.cin ./Build/Intermediate/LibChewing-CHS/phone.cin
	@mv ./Build/tsi-chs.src ./Build/Intermediate/LibChewing-CHS/tsi.src
	@mv index_tree.dat dictionary.dat ./Build/Release/LibChewing-CHS/

libv-cht:
	@mkdir -p ./Build/Release/LibChewing-CHT/
	@mkdir -p ./Build/Intermediate/LibChewing-CHT/
	@swift ./bin/cook_libchewing.swift cht
	@diff -u "./Build/phone-cht.cin" "./Build/phone-cht-ex.cin" --label phone.cin --label phone-CNS11643-complete.cin > "./Build/Intermediate/LibChewing-CHT/phone.cin-CNS11643-complete.patch" || true
	@./bin/libchewing-database-initializer/init_database ./Build/phone-cht.cin ./Build/tsi-cht.src
	@mv ./Build/phone-cht.cin ./Build/Intermediate/LibChewing-CHT/phone.cin
	@mv ./Build/tsi-cht.src ./Build/Intermediate/LibChewing-CHT/tsi.src
	@mv index_tree.dat dictionary.dat ./Build/Release/LibChewing-CHT/

install-vchewing: macv
	@echo "\033[0;32m//$$(tput bold) macOS: 正在部署威注音核心語彙檔案……$$(tput sgr0)\033[0m"
	@mkdir -p $(HOME)/Library/Containers/org.atelierInmu.inputmethod.vChewing/Data/Library/Application\ Support/vChewingFactoryData/
	@cp -a ./Build/Release/vChewingFactoryDatabase.sqlite $(HOME)/Library/Containers/org.atelierInmu.inputmethod.vChewing/Data/Library/Application\ Support/vChewingFactoryData/

	@pkill -HUP -f vChewing || echo "// vChewing is not running"
	@echo "\033[0;32m//$$(tput bold) macOS: 核心語彙檔案部署成功。$$(tput sgr0)\033[0m"

# FOR INTERNAL USE

_remoteinstall-vchewing: macv
	@rsync -avx ./components/common/data-*.json $(RHOST):"Library/Containers/org.atelierInmu.inputmethod.vChewing/Data/Library/Application\ Support/vChewingFactoryData/"
	@test "$(RHOST)" && ssh $(RHOST) "pkill -HUP -f vChewing || echo Remote vChewing is not running" || true

gc:
	git reflog expire --expire=now --all ; git gc --prune=now --aggressive

gitcfg:
	cp .config_backup .git/config
