# How this script works

1. the ```build output directory``` is determined. Baseline and business application should already be deployed to this location. Contents should include (new) binaries, ```web.<module>.<role>.xml``` and ```parameters.<module>.<role>.xml``` files
2. previously built build artifacts are discovered. If none, a new wdp will be created, otherwise, that previously package will be _updated_!~
3. web.config transformations and parameters.xml are merged for a specific role and the web.config transformation will be applied on the web.base.role.config of the baseline package
4. the newly generated web.config will be copied to the ```build output directory```
5. msdeploy will be run to create or update a wdp package for the specific role. Using the -Skip parameter all the role specific parameters.xml and web.configs will be _ignored_
6. output will be stored in ```generated wdp```. 