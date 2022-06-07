FROM public.ecr.aws/lambda/nodejs:16
COPY index.js package.json package-lock.json ${LAMBDA_TASK_ROOT}/src/
WORKDIR ${LAMBDA_TASK_ROOT}/src
RUN npm install --production
CMD [ "src/index.lambdaHandler" ]