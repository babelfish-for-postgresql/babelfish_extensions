- [Contributing to Babelfish](#contributing-to-babelfish)
  - [Ways to Contribute](#ways-to-contribute)
    - [Reporting Bugs](#reporting-bugs)
    - [Security issue notifications](#security-issues-notifications)
    - [Contributing via Pull Requests](#contributing-via-pull-requests)
    - [Finding contributions to work on](#finding-contributions-to-work-on)
    - [Submiting Feature Requests](#submiting-feature-requests)
    - [Documentation Changes](#documentation-changes)
  - [Code of Conduct](#code-of-conduct)
  - [Developer Certificate of Origin](#developer-certificate-of-origin)
  - [Review Process](#review-process)
  - [Licensing](#licensing)


# Contributing to Babelfish

Thank you for your interest in contributing to our project. Whether it's a bug report, new feature, correction, or additional documentation, we greatly value feedback and contributions from our community.

Please read through this document before submitting any issues or pull requests to ensure we have all the necessary information to effectively respond to your bug report or contribution.

## Ways to Contribute

1. **Please note:** Babelfish adds additional syntax, functions, data types, and more to [PostgreSQL](https://github.com/postgres/postgres) to help in the migration from SQL Server. This repository contains the four extensions that comprise Babelfish. Note that these extensions depend on patches to community PostgreSQL. A repository of those modifications can be found [here](https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish). You may submit Pull Requests for any of these extensions in this repo. For more information about Pull Requests, please refer to [Github PR docs](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests).

2. **When in doubt, open an issue** - For almost any type of contribution, the first step is opening an issue. Even if you think you already know what the solution is, writing down a description of the problem you're trying to solve will help everyone get context when they review your pull request. If it's truly a trivial change (e.g. spelling error), you can skip this step -- but as the subject says, when in doubt, [open an issue](https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish/issues).

3. **Only submit your own work** (or work you have sufficient rights to submit) - Please make sure that any code or documentation you submit is your work or you have the rights to submit. We respect the intellectual property rights of others, and as part of contributing, we'll ask you to sign your contribution with a "Developer Certificate of Origin" (DCO) that states you have the rights to submit this work and you understand we'll use your contribution. There's more information about this topic in the [DCO section](#developer-certificate-of-origin).

### Reporting Bugs

We welcome you to use the GitHub issue tracker for bug reporting. When filing an issue, please check existing open, or recently closed, issues to make sure somebody else hasn't already reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

* Use the corresponding _Bug template_.
* A reproducible test case or series of steps
* The version of our code being used
* Any modifications you've made relevant to the bug
* Anything unusual about your environment or deployment

### Security issue notifications
If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public github issue.


### Contributing via Pull Requests
Contributions via pull requests are much appreciated. Before sending us a pull request, please ensure that:

1. You are working against the latest source on the *main* branch.
2. You check existing open, and recently merged, pull requests to make sure someone else hasn't addressed the problem already.
3. You open an issue to discuss any significant work - we would hate for your time to be wasted.

To send us a pull request, please:

1. Fork the repository.
2. Modify the source; please focus on the specific change you are contributing. If you also reformat all the code, it will be hard for us to focus on your change.
3. Ensure local tests pass.
4. Commit to your fork using clear commit messages.
5. Send us a pull request, answering any default questions in the pull request interface.
6. Pay attention to any automated CI failures reported in the pull request, and stay involved in the conversation.

GitHub provides additional document on [forking a repository](https://help.github.com/articles/fork-a-repo/) and
[creating a pull request](https://help.github.com/articles/creating-a-pull-request/).


### Finding contributions to work on

Looking at the existing issues is a great way to find something to contribute on. As our projects, by default, use the default GitHub issue labels (enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at any 'help wanted' issues is a great place to start.

### Submiting Feature Requests

We are welcome to hear from the community about all the enhacements related to improve the Babelfish project.

* Use the corresponding _Enhancement template_ in the issue tracker.
* If you will to submit code related to the feature request, please open a Pull Request and reference the opened issue.
* Follow the practices described at [Contributing via Pull Requests](#contributing-via-pull-requests).

### Documentation Changes

If you would like to contribute to the documentation, please do so in the [website](https://github.com/babelfish-for-postgresql/babelfish_project_website) repo. 


## Code of Conduct

This project has adopted the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct). 

For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq) or contact `opensource-codeofconduct@amazon.com` with any additional questions or comments.

## Developer Certificate of Origin

Babelfish is an open source product released under the Apache 2.0 and PostgreSQL license (see [the Apache site](https://www.apache.org/licenses/LICENSE-2.0) or the [LICENSE.Apache2 license file](./LICENSE.Apache2), and the [PostgreSQL license file](./LICENSE.PostgreSQL) ). The Apache 2.0 license and the PostgreSQL license allow you to freely use, modify, distribute, and sell your own products that include Apache 2.0 licensed or PostgreSQL licensed software.

We respect intellectual property rights of others and we want to make sure all incoming contributions are correctly attributed and licensed. A Developer Certificate of Origin (DCO) is a lightweight mechanism to do that.

The DCO is a declaration attached to every contribution made by every developer. In the commit message of the contribution, the developer simply adds a `Signed-off-by` statement and thereby agrees to the DCO, which you can find below or at [DeveloperCertificate.org](http://developercertificate.org/).

```
Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the
    best of my knowledge, is covered under an appropriate open
    source license and I have the right under that license to
    submit that work with modifications, whether created in whole
    or in part by me, under the same open source license (unless
    I am permitted to submit under a different license), as
    Indicated in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including
    all personal information I submit with it, including my
    sign-off) is maintained indefinitely and may be redistributed
    consistent with this project or the open source license(s)
    involved.
 ```

We require that every contribution to Babelfish is signed with a Developer Certificate of Origin. Additionally, please use your real name. We do not accept anonymous contributors nor those utilizing pseudonyms.

Each commit must include a DCO which looks like this

```
Signed-off-by: Jane Smith <jane.smith@email.com>
```
You may type this line on your own when writing your commit messages. However, if your user.name and user.email are set in your git configs, you can use `-s` or `--signoff` to add the `Signed-off-by` line to the end of the commit message.

## Review Process

We deeply appreciate everyone who takes the time to make a contribution. We will review all contributions as quickly as possible. As a reminder, [opening an issue](https://github.com/babelfish-for-postgresql/babelfish_extensions/issues/new) discussing your change before you make it is the best way to smooth the PR process. This will prevent a rejection because someone else is already working on the problem, or because the solution is incompatible with the architectural direction.

During the PR process, expect that there will be some back-and-forth. Please try to respond to comments in a timely fashion, and if you don't wish to continue with the PR, let us know. If a PR takes too many iterations for its complexity or size, we may reject it. Additionally, if you stop responding we may close the PR as abandoned. In either case, if you feel this was done in error, please add a comment on the PR.

If we accept the PR, a [maintainer](./MAINTAINERS.md) will merge your change and usually take care of backporting it to appropriate branches ourselves.

If we reject the PR, we will close the pull request with a comment explaining why. This decision isn't always final: if you feel we have misunderstood your intended change or otherwise think that we should reconsider then please continue the conversation with a comment on the PR and we'll do our best to address any further points you raise.


## Licensing

This work is dual-licensed under [Apache 2.0 license](./LICENSE.Apache2) and [PostgreSQL license](./LICENSE.PostgreSQL). You can use
the software under either license.

The Babelfish community requires contributions to be made under the terms of the Apache 2.0 and PostgreSQL licenses. In addition, contributors grant any person obtaining a copy of the contribution permission to relicense all or a portion of their contribution to the PostgreSQL license solely to contribute all or a portion of their contribution to the PostgreSQL open source project.
