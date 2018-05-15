from django.shortcuts import render
from models import User, Message

def base(request):
    ''' Send out post requests via SMTP '''

    user = User()

    if request.method == 'POST':
        message = Message(user=user,text=request.POST['q'])
        message.send_message()

    else:
        message = Message(user=user, text='NO POST')

    return render(request, 'base/home.html', {'message':message})