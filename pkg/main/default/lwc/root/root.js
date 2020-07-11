import {LightningElement} from 'lwc';
//eslint-disable-next-line
import UserEvents from '@salesforce/resourceUrl/userEvents'; //Need to use window.UserEvents in LWC
import getUserProperties from '@salesforce/apex/UserEventsController.getUserProperties';
import ERROR from '@salesforce/messageChannel/Error__c';
import SUCCESS from '@salesforce/messageChannel/Success__c';
import {proxify,subscribeToMessageChannel,showError} from 'c/utils';
import {createMessageContext,releaseMessageContext} from 'lightning/messageService';
import getAuthStatus from '@salesforce/apex/AuthController.getAuthStatus';
import getConfigAfterAuthorization from '@salesforce/apex/AuthController.getConfigAfterAuthorization';
import beginOAuth from '@salesforce/apex/AuthController.beginOAuth';
import defaultLoadingTemplate from './defaultLoadingTemplate.html';
import authorizationTemplate from './authorizationTemplate.html';
import AuthorizeDocuSignInstructions from '@salesforce/label/c.AuthorizeDocuSignInstructions';
import AuthorizeButtonLabel from '@salesforce/label/c.AuthorizeButton';

const authSettingsSymbol = Symbol('authSettings');
const authRequiredSymbol = Symbol('authRequired');
const requiredProductsSymbol = Symbol('requiredProducts')
const userEventsSymbol = Symbol('userEvents'); 

const handleAuthStatusResponse = (
    { 
        isAuthorized, 
        products = [], 
        isConsentRequired, 
        message, 
        eventOrigins
    }, 
    requiredProducts = []) => {
        if (isAuthorized) {
            const requiredProductsSet = new Set(requiredProducts);
            for (const { name, isExpired } of products) {
                if(isExpired) continue;
                else if (requiredProductsSet.has(name)) requiredProductsSet.delete(name);
            }
            return {
                isAuthorizedComplete : true,
                isAuthorized: requiredProductsSet.size === 0,
                isConsentRequired: isConsentRequired, 
                message: message, 
                eventOrigins : eventOrigins
            };
        }
        
        return {
            isAuthorizedComplete : true,
            isAuthorized: false,
            isConsentRequired: isConsentRequired, 
            message: message, 
            eventOrigins : eventOrigins
        };
}

export default class RootContainer extends LightningElement {  
    rootLabels = {
        AuthorizeDocuSignInstructions,
        AuthorizeButtonLabel
    };
    state = proxify({
        [authSettingsSymbol]: {
            isAuthorizedComplete : false,
            isAuthorized: false,
            isConsentRequired: null, 
            message: null, 
            eventOrigins : null
        },
        [requiredProductsSymbol] : [],
        [authRequiredSymbol] : true,
        [userEventsSymbol] : null,
        isLoading: false
    });
    constructor(settings = {}) {
        super();
        const { useAuth = true, products = ['e_sign'], isLoading = false, useEvents = true, loadingTemplate = null } = settings;
        this.loadingTemplate = loadingTemplate ? loadingTemplate : defaultLoadingTemplate;
        this.isLoading = isLoading;
        this.events = {};
        if (useEvents) this.context = createMessageContext();
        this.setState({
            [authRequiredSymbol]: useAuth,
            [requiredProductsSymbol]:  products
        })
    }

    get authStatus() {
        return Object.freeze(this.state[authSettingsSymbol]);
    }

    get authUserMessage() {
        return this.authStatus.message;
    }

    get isAuthConsentRequired(){
        return this.authStatus.isConsentRequired;
    }    

    get showAuthSettings() {
        return this.authStatus ? this.authStatus.isAuthorizedComplete && !this.authStatus.isAuthorized : false;
    }

    get isContentReady() {
        return !this.showAuthSettings && !this.isLoading;
    }

    get userEvents() {
        return this.state[userEventsSymbol];
    }

    get isLoading() {
        return this.state.isLoading;
    }

    set isLoading(val) {
        this.setState({
            isLoading: val === true ? true : false
        })
    } 
    
    connectedCallback() {
        this.initUserEvents();
        if (this.state[authRequiredSymbol]) this.getAuthentication(this.state[requiredProductsSymbol]).then(response => {
            this.setState({
                [authSettingsSymbol] : response
            });
            return this.componentLoad();
        })
        .catch(err => this.errorToast(err));
        else this.componentLoad();
    }

    initUserEvents() {
        getUserProperties()
        .then(
            result => {
                this.setState({
                    [userEventsSymbol] : new window.UserEvents(
                        result.application, 
                        result.version, 
                        result.environment, 
                        result.accountIdHash, 
                        result.userIdHash
                    )
                })
            }
        )
        .catch(err => {
            this.errorToast(err)
        });

    }

    addEventSubscription(name, event, callback) {
        try {
            this.events[name] = subscribeToMessageChannel(
                this.context,
                null,
                event,
                callback
            )
        } catch(err) {
            this.errorToast(err);
        }
    }

    getAuthentication(requiredProducts = []) {
        return new Promise((resolve, reject) => {
            getAuthStatus()
            .then((response) => {
                resolve(handleAuthStatusResponse(response, requiredProducts));
            })
            .catch(err => reject(err));
        })
    }

    beginOAuth() {
        const authStatus = this.authStatus;
        beginOAuth({target: window.location.origin})
        .then(loginUrl => {
            var width = 600;
            var height = 600;
            var left = screen.width / 2 - width / 2;
            var top = screen.height / 2 - height / 2;
        
            const onMessage = function ({ data, source }) {
                // event must originate from Visualforce page on our domain
                if (authStatus.eventOrigins && authStatus.eventOrigins.indexOf(event.origin) !== -1) {
                    window.removeEventListener('message', onMessage);
                    const success = data.loginInformation && data.loginInformation.status === 'Success';
                    getConfigAfterAuthorization().then(response => {
                        let finalResult = handleAuthStatusResponse(response);
                        finalResult.isAuthorized = success;
                        finalResult.isConsentRequired = !success;
                        this.setState({
                            [authSettingsSymbol]: finalResult  
                        })
                        //Todo. Add logic for hiding ds-app-auth
                        if (source) source.close();
                    }).catch(err =>  this.errorToast(err))
                }
            };
            const oauthWindow = window.open(loginUrl, 'ds-oauth', 'width=' + width + ',height=' + height + ',left=' + left + ',top=' + top);
            window.addEventListener('message', onMessage);
            oauthWindow.focus();
        })
        .catch(err => this.errorToast(err));
    }

    setState(updates = {}) {
        this.state = proxify({
           ...this.state,
           ...updates
        })
    }

    successToast(message) {
        if (!this.context) return;
        showError(this.context, message, SUCCESS)
    }

    errorToast(message) {
        if (!this.context) return;
        showError(this.context, message, ERROR);
    }

    disconnectedCallback() { 
        if (this.componentClose) this.componentClose();
        releaseMessageContext(this.context)
    }    

    render() {
        return this.showAuthSettings ? authorizationTemplate : this.isContentReady ? this.content : this.loadingTemplate;
    }
}