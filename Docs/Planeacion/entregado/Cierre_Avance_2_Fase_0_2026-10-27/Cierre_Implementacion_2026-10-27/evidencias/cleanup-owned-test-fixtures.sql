BEGIN;
DELETE FROM user_tenants WHERE user_id IN ('cmvrajo7r002bhvuhuxxtq0ev','cmvrajo88002chvuhf4gaphwq','cmvrajo8o002dhvuh80n5j9fw','cmvrajo97002ehvuhfu267ho9','cmvrajq75002ohvuhscdb2md2','cmvraoc7f0008z6c8xi98t0s6','cmvraoc7s0009z6c884rnts17','cmvraoc82000az6c8q7nh7yf5','cmvraoc8b000bz6c8f5cym4sy','cmvraoe38000lz6c8xocecdhw') AND tenant_id IN ('cmvrajo490023hvuhbptubalx','cmvrajo5m0024hvuhr7rjol9s','cmvraoc3f0000z6c8f4jj4izt','cmvraoc5g0001z6c8y089sfht');
DELETE FROM roles WHERE tenant_id IN ('cmvrajo490023hvuhbptubalx','cmvrajo5m0024hvuhr7rjol9s','cmvraoc3f0000z6c8f4jj4izt','cmvraoc5g0001z6c8y089sfht');
DELETE FROM tenants WHERE id IN ('cmvrajo490023hvuhbptubalx','cmvrajo5m0024hvuhr7rjol9s','cmvraoc3f0000z6c8f4jj4izt','cmvraoc5g0001z6c8y089sfht');
DELETE FROM users WHERE id IN ('cmvrajo7r002bhvuhuxxtq0ev','cmvrajo88002chvuhf4gaphwq','cmvrajo8o002dhvuh80n5j9fw','cmvrajo97002ehvuhfu267ho9','cmvrajq75002ohvuhscdb2md2','cmvraoc7f0008z6c8xi98t0s6','cmvraoc7s0009z6c884rnts17','cmvraoc82000az6c8q7nh7yf5','cmvraoc8b000bz6c8f5cym4sy','cmvraoe38000lz6c8xocecdhw');
COMMIT;
SELECT count(*) FROM tenants;
