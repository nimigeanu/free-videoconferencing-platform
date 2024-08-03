# Self managed open source video conferencing platform

## Features
* Based on open source [LiveKit](https://github.com/livekit/livekit)
* Suports audio/video, chat, screen share etc

![Example Image](https://github.com/livekit-examples/meet/raw/main/.github/assets/livekit-meet.jpg)

* Runs in the cloud
* WebRTC driven
* Sets itself up with all required servers (LiveKit, TURN, Next) and SSL certificates

## Setup

### Deploying the stack
1. Sign in to the [AWS Management Console](https://aws.amazon.com/console)
2. You will need a domain that you can create new DNS entries for; if this is managed via Route53, create a [Hosted Zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html) for it; othewise you'll have to manually create some A records in the end
3. click the button below to launch the CloudFormation template. Alternatively you can [download](template.yaml) the template and adjust it to your needs.

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/create/review?stackName=video-conferencing-platform&templateURL=https://s3.amazonaws.com/lostshadow/free-videoconferencing-platform/template.yaml)

4. Choose a name for your stack
5. Adjust the parameters:
	* `DomainName` - Replace with the domain name you have access to. The demo will be installed on a subdomain of this domain, named according to the stack name specified above
	* `InstanceType` - Server Instance Type. Larger instances will be able to accomodate more rooms and users
	* `IsRoute53Managed` - Set to yes if the domain is managed by Route53 and you have already created a [hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html) for it. Otherwise, change it to `no`


6. Check the `I acknowledge that AWS CloudFormation might create IAM resources` box. This confirms you agree to have some required IAM roles and policies created by CloudFormation.
7. Hit the `Create stack` button. 
8. Wait for the `Status` of your CloudFormation template to become `CREATE_COMPLETE`. Note that this may take **2-3 minutes** or more.
9. Check the `Outputs` section of your CloudFormation template. **ONLY** If you set `IsRoute53Managed` to `no`, you will find instructions to manually create two DNS records. Please create these records now, and wait a few* minutes for these to take effect before moving to the next step.
10. Also under `Outputs`, click the `VideoConferenceLink`. This may not work at first, keep waiting/refreshing until it does. It may take up to __5 minutes__ or more as the server installs software and performs initializations
11. Allow camera and microphone access if requested. Type any name in the `username` field and hit `Join Room`. 
12. Play around with it, the controls are quite intuitive.
13. Duplicate the room URL and add more users to it, under different usernames.
14. Alter the last 4 characters of the URL to create different rooms. 
15. That's it, enjoy!

### Customization

What you just fiddled around with is a clone of [this](https://github.com/livekit-examples/meet) LiveKit example. LiveKit itself comes with a set of pre-built [components](https://github.com/livekit/components-js), of which what you're seeing is an instance the [VideoConference](https://docs.livekit.io/reference/components/react/component/videoconference/) component. If you [take a look](https://github.com/livekit/components-js/blob/main/packages/react/src/prefabs/VideoConference.tsx) at it, you'll find that it's made with other components like 
* [Chat](https://github.com/livekit/components-js/blob/main/packages/react/src/prefabs/Chat.tsx) - a chat of course
* [GridLayout](https://github.com/livekit/components-js/blob/main/packages/react/src/components/layout/GridLayout.tsx) -  displays the participants in a grid where every participants has the same size 
* [FocusLayout](https://github.com/livekit/components-js/blob/main/packages/react/src/components/layout/FocusLayout.tsx) - displays the focused (speaking) participant in a larger main component, and the others in a carousel of smaller icons
* [ControlBar](https://github.com/livekit/components-js/blob/main/packages/react/src/prefabs/ControlBar.tsx) - buttons for camera, microphone, screenshare, leave room

Needless to say, one can use, style, fork, extend, combine all these to make their own apps and still take advantage of the solid and coherent LiveKit context for connectivity and security in a non-proprietary self-hosted environment. 

### Integration

Ok, you're happy with how your customized video coference looks now, but you now want to control usernames and access to rooms. LiveKit handles these via __tokens__:
* your backend will need to generate tokens and pass these to clients through a custom channel
* a token securely encodes 
	* one's name and username 
	* room that it has access to 
	* if they can send video to the room or just watch/listen 
	* how long it's valid for
	* ...and a few other params
* in the demo that you just played with, the script responsible for generating tokens was [this](https://github.com/livekit-examples/meet/blob/main/pages/api/token.ts); you may customize it or start from scratch
* [here](https://docs.livekit.io/realtime/server/generating-tokens/)'s the quick start on how to generate tokens yourself 

### Notes
* You may at times run into an error like `Resource handler returned message: "Your requested instance type (t3.medium) is not supported in your requested Availability Zone (us-east-1d). Please retry your request by not specifying an Availability Zone or choosing...`. In this situation the easiest thing to do is just try again. If it fails repeatedly, try another instance type.
* [LiveKit](https://livekit.io/) is a for-profit. While they open-source much of their software, they charge for running streams through their cloud (instead of on your own servers) and for access to some advanced/enterprise features. This post is not endorsed or supported by LiveKit or any other entity.
* *If you're creating the DNS entries manually (step 9 above), do not hurry up accessing an url that includes it (i.e. clicking on the link in step 10); in some network environments an intermediate DNS may cache the NXDOMAIN (while the domain is not yet ready) and hold on to it for a long time, thus making it look like the record is invalid; waiting 2-3 minutes is usually enough, yet on the first attempt give it a good 5 min to be safe