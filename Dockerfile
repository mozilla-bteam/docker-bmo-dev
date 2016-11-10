# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

FROM mozillabteam/bmo-ci
MAINTAINER David Lawrence <dkl@mozilla.com>

# Distribution package installation
COPY conf/rpm_list /
RUN yum -y -q install `cat /rpm_list` && yum clean all

# Sudoers setup
COPY conf/sudoers /etc/sudoers
RUN chown root.root /etc/sudoers && chmod 440 /etc/sudoers

# Supervisor setup
COPY conf/supervisord.conf /etc/supervisord.conf
RUN chmod 700 /etc/supervisord.conf

# Copy setup scripts
COPY scripts/* /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

# Apache fixes
RUN  sed -e "s?^User apache?User $BUGZILLA_USER?" --in-place /etc/httpd/conf/httpd.conf
RUN  sed -e "s?^Group apache?Group $BUGZILLA_USER?" --in-place /etc/httpd/conf/httpd.conf

# Development environment setup
RUN git clone $GITHUB_BASE_GIT -b $GITHUB_BASE_BRANCH $BUGZILLA_ROOT \
    && ln -sf $BUGZILLA_LIB $BUGZILLA_ROOT/local
COPY conf/checksetup_answers.txt $BUGZILLA_ROOT/checksetup_answers.txt
RUN bugzilla_config.sh
RUN su - $BUGZILLA_USER -c dev_config.sh

RUN chown -R $BUGZILLA_USER.$BUGZILLA_USER $BUGZILLA_ROOT /home/$BUGZILLA_USER

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
