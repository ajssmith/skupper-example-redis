FROM registry.fedoraproject.org/fedora

RUN dnf -y --nodocs install nodejs && dnf -y clean all

WORKDIR /usr/src/app

COPY package.json ./

RUN npm install

COPY app.js .

EXPOSE 5050

CMD ["node", "app.js"]
