FROM public.ecr.aws/lambda/nodejs
COPY index.js package.json ${LAMBDA_TASK_ROOT}/src/
WORKDIR ${LAMBDA_TASK_ROOT}/src
RUN npm install --production
CMD [ "index.lambdaHandler" ]