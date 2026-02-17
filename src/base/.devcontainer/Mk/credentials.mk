.PHONY: aws-configure aws-login create-npmrc github-login

aws-configure:
	aws configure sso --region eu-west-2

aws-login:
	aws sso login --sso-session sso-session

create-npmrc: github-login
	echo "//npm.pkg.github.com/:_authToken=$$(gh auth token)" > .npmrc
	echo "@nhsdigital:registry=https://npm.pkg.github.com" >> .npmrc

github-login:
	gh auth login --scopes read:packages
