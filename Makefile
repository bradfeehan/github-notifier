.PHONY: install uninstall test

install:
	./install.sh

uninstall:
	./uninstall.sh

test:
	shunit2 test/github_notif_test.sh
	./test/configure_test.sh
	./test/prompter_test.sh
	./test/url_test.sh
	./test/mock_test.sh
